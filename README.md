# Planetary Computer Hub

[![Hub - production](https://img.shields.io/badge/Hub-production-blue)](http://planetarycomputer.microsoft.com/compute)
[![Hub - staging](https://img.shields.io/badge/Hub-staging-blue)](http://planetarycomputer-staging.microsoft.com/compute)

> [!NOTE]
> The Planetary Computer Hub will be retired on the 6th of June 2024. See https://github.com/microsoft/PlanetaryComputer/discussions/347 for more.

This repository contains the configuration and continuous deployment for the [Planetary Computer's Hub][hub], a [Dask-Gateway][gateway] enabled [JupyterHub][jupyterhub] deployment focused on supporting scalable geospatial analysis.

For general questions or discussions about the Planetary Computer, use the [microsoft/PlanetaryComputer](http://github.com/microsoft/PlanetaryComputer) repository.

## Overview

See the [user documentation][hub] for an overview of what all is provided.

This deployment is relatively complex, and contains a few Microsoft Planetary Computer-specific aspects. For developers or system administrators looking to deploy their own hub, consult the [deployment guide][deployment guide]. This can serve as a concrete example.

There are two main components to the `planetary-computer-hub` repository:

1. `helm`: A wrapper around the `daskhub` helm chart.
2. `terraform`: Terraform code to deploy all the necessary Azure resources and the Hub itself.

## Helm

The most interesting pieces are the YAML configuration files. These are used by the Terraform helm-release provider to customize the JupyterHub and Dask Gateway charts (see `hub.tf`). In addition to these `values_files`, the `hub.tf` terraform module passes some terraform variables through to the chart using `set` blocks.

The bulk of the configuration is done in `values.yaml`. See the inline comments there for documentation on why those values are set.

`profiles.yaml` configures `daskhub.jupyterhub.singleuser.ProfileList`. The helm-release provider does not lend itself to setting List values, and we need to get the various image tags from the terraform configuration. We place this in its own file to keep things a bit more manageable.

`jupyterhub_opencensus_monitor.yaml` sets `daskhub.jupyterhub.hub.extraFiles.jupyterhub_open_census_monitor.stringData` to be the `jupyterhub_opencensus_monitor.py` script (see below). We couldn't figure out out to get the helm-release provider working with with kubectl's `set-file` so we needed to inline the script. There's probably a better way to do this.

Finally, the custom UI elements used by the Hub process and additional notebook server configuration are included under `helm/chart/files` and `helm/cart/templates`. These are mounted into the pods. See [custom UI](#custom-ui) for more.

## Terraform

The `terraform` directory contains all the deployment code for the Hub. It manages the Azure resources and Helm release.

The terraform code is split into deployment-specific directories (`prod`, `staging`) and a `resources` directory that contains the shared configuration between the two deployments. To the extent possible, resources should be defined in `resources`. `staging` and `prod` should only contain configuration (e.g. the URL for the hub, or the size of the core VM).

Additionally, there's a `shared` directory, which contains the definition for resources that are shared between the two. Currently, this includes a Storage Account and file share for mounting data volumes onto notebook pods. Resources in the `shared` directory are deployed manually.

### acr.tf

This module creates the [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/) used for Hub images. Its deployment is a bit strange, an artifact of the deployment history and a desire
to use the same container registry for both the staging and prod deployments.

These images are available publicly through the Microsoft Container Registry. See <https://github.com/microsoft/planetary-computer-containers> for more.

### aks.tf

This module deploys the Kubernetes cluster using [Azure Kubernetes Service][aks].

Most of the configuration is around node pools. We use the default node pool for "core" JupyterHub pods (e.g. the hub pod). We add a `user_pool` for users, and a `cpu_worker_pool` for Dask workers (using preemptible nodes).

In addition to the node pools configured here, we attach two GPU node pools. See `scripts/gpu`. We're following this [upstream issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/6793) to deploy GPU node pools through terraform.

### hub.tf

This uses the [helm_release](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) provider to deploy the Hub using our Helm chart. See [helm](#helm) above for more.

### keyvault.tf

We manually place some secrets in an [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/). These are accessed in `keyvault.tf` and used in the deployment. The [Azure Service Principal][sp] used by Terraform must have permissions to read these keys.

### logs.tf

This deploys a Log Analytics workspace, Log Analytics solution, and application insights.

### outputs.tf

A terraform values are used later in the process (e.g. the Kubernetes configuration to start tests). These are exported in `outputs.tf`.

### providers.tf

This sets the versions of the Terraform [providers](https://registry.terraform.io/browse/providers) we use.

### rg.tf

Creates a Resource Group to contain all the created Azure resources.

### variables.tf

Defines the variables that can be controlled by the staging / prod deployments. See the variable descriptions for documentation on what each variable is used for.

### vnet.tf

Creates the [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) used by the Kubernetes Cluster.

### data-volumes.tf

Creates an Azure Storage Account, File share, and Kubernetes Secret for mounting the file share. This is used to mount read-only, static files into all the user
pods (e.g. a dataset for a machine learning competition).

## Manual Resources

We rely on a few "manual" resources that are created outside of this repository. These include

- A storage account and container for Terraform state
- A keyvault for secrets

The service principal used by Terraform should have access to the manual resources resource group.

### Keyvault secrets reference

This table documents the values we set in keyvault. They can be created with

```console
$ az keyvault secret set --vault-name pc-deploy-secrets --name '<prefix>--<key-name>' --value '<key-value>'
```
|                Keyvault Key                |                                                                          Description                                                                          |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| pcc-staging--jupyterhub-proxy-secret-token | Sets `daskhub.jupyterhub.proxy.secretToken` for the staging JupyterHub                                                                                        |
| pcc-prod--jupyterhub-proxy-secret-token    | Sets `daskhub.jupyterhub.proxy.secretToken` for the prod JupyterHub                                                                                           |
| pcc--id-client-secret                      | Sets `daskhub.jupyterhub.hub.config.GenericOAuthenticator.client_secret`, an Oauth token to communicate with the pc-id oauth provider                         |
| pcc--pc-id-token                           | Sets `daskhub.jupyterhub.hub.extraEnv.PC_ID_TOKEN`, an API token with the pc-id application to look up users, enabling the API management integration         |
| pcc-staging--kbatch-server-api-token       | JupyterHub token for the kbatch application in staging.                                                                                                       |
| pcc-prod--kbatch-server-api-token          | JupyterHub token for the kbatch application in production.                                                                                                    |
| pcc--velero-azure-subscription-id          | Set in `velero_credentials.tpl` for backups / migrations                                                                                                      |
| pcc--velero-azure-tenant-id                | Set in `velero_credentials.tpl` for backups / migrations                                                                                                      |
| pcc--velero-azure-client-id                | Set in `velero_credentials.tpl` for backups / migrations                                                                                                      |
| pcc--velero-azure-client-secret            | Set in `velero_credentials.tpl` for backups / migrations                                                                                                      |


```
az keyvault secret set --vault-name pc-deploy-secrets -n pcc-test-jupyterhub-proxy-secret-token --value (openssl rand -hex 32)
```

## Continuous deployment

This repository deploys on commits to the staging environment on commits `main`. We commit to production on tags.
The deployment is done through GitHub Actions.

We created a service principal to mange deployment.

To enable creating network security groups

```
$ az role assignment create \
    --role "/subscriptions/<subscription-id>/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" \
    --assignee "<service-principal-id>" \
    --scope="/subscriptions/<subscription-id>/resourceGroups/MC_pcc-staging-rg_pcc-staging-cluster_westeurope/providers/Microsoft.Network/routeTables/aks-agentpool-27180469-routetable"
```

Likewise for production (change the resource group name in the scope).


## AKS RBAC

Requires the service principal executing terraform to also have permissions on the Kubernetes Cluster.

```
$ az role assignment create \
    --role "Azure Kubernetes Service RBAC Writer" \
    --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/pcc-staging-2-rg/providers/Microsoft.ContainerService/managedClusters/pcc-staging-2-cluster" \
    --assignee $ARM_CLIENT_ID
```

## Velero backup configuration

The Terraform deployment also installs [velero](https://velero.io/) on the cluster via helm. See `velero.tf`.

This requires the manual creation of some resources.

## Opencensus monitor service

`jupyterhub_opencensus_monitory.py` module is deployed as a [JuptyerHub service][hub-service]. It collects metrics on usage from the JupyterHub REST API. It would ideally be refactored into a standalone repository: <https://github.com/jupyterhub/jupyterhub/issues/3116>.

## API Management integration

The Planetary Computer API is deployed using API Management. The hub includes an integration to automatically insert the logged in user's subscription key as an environment variable. This is used by libraries like [`planetary-computer`](https://github.com/microsoft/planetary-computer-sdk-for-python) to automatically sign requests.
See `daskhub.jupyterhub.hub.extraConfig.pre_spawn_hook` in `values.yaml` for where this is done.

## Testing

We used the JupyterHub admin panel to create a user for tests, `pangeotestbot@microsoft.com`.
The `tests/` starts a notebook server for this user and verifies that a few common operations work.

## ACR Integration

A previous iteration used a common Azure Container Registry for both staging and prod. After splitting, we need to manually grant the staging cluster access to the ACR.

```
$ az aks update -n pcc-staging-cluster -g pcc-staging-rg --attach-acr pcccr
```

## Custom UI

We're able to customize the JupyterHub and jupyterlab UIs following the approach outlined in <https://discourse.jupyter.org/t/customizing-jupyterhub-on-kubernetes/1769/4>.

To test changes to the templates locally, [install jupyterhub](https://jupyterhub.readthedocs.io/en/stable/installation-guide.html) and run it from the root of the project directory, which includes a `jupyterhub_config.py` file. Changes to the template files in `helm/chart/files/etc/jupyterhub/templates/` can be previewed at `localhost:8000`.

## Ingress

This setup uses [Application Gateway Ingress Controller][agic] to serve traffic
over HTTPs without directly exposing the Kubernetes cluster to the internet.

We've chosen to create and manage the Application Gateway *outside* of
Terraform. The Ingress Controller also wants to make changes to it as Ingress
routes are added, causing some ownership conflicts over the Application Gateway.

```
set -x RESOURCE_GROUP ... # RG with the AKS cluster
set -x KEYVAULT_NAME ...  # Keyvault with the TLS cert
set -x VNET_NAME ...      # VNET with the AKS cluster
set -x SUBNET_NAME ...    # Subnet with the AKS cluster
set -x APPGW_NAME ...     # pick whatever
set -x PUBLIC_IP ...      # the name of the public IP created by Terraform
set -x MI_NAME pcc-mi     # The name of the managed identity created by Terraform
set -x CLUSTER_NAME ...   # The name of the AKS cluster

# Derived variables
set -x MI_CLIENT_ID (az identity show -n $MI_NAME -g $RESOURCE_GROUP --query clientId -o tsv)
set -x MI_SCOPE (az identity show -g $RESOURCE_GROUP -n $MI_NAME --query id -o tsv)
set -x RG_ID (az group show -n $RESOURCE_GROUP --query id -o tsv)
```

With these variables set, we can create the Application Gateway and configure
it. If you're deploying from scratch, you'll need to do a `terraform apply`
first with `data.azurerm_application_gateway.pc_compute` disabled, along with
all references to it (e.g. in the AKS cluster)

```
# az keyvault network-rule add --subnet (az network vnet subnet show -n $SUBNET_NAME -g $RESOURCE_GROUP --vnet-name $VNET_NAME --query id -o tsv) -n $KEYVAULT_NAME

az network application-gateway create \
	-n $APPGW_NAME \
	-g $RESOURCE_GROUP \
	--sku Standard_v2 \
	--public-ip-address $PUBLIC_IP \
	--vnet-name $VNET_NAME \
	--subnet $SUBNET_NAME \
	--priority 19500

set -x APPGW_ID (az network application-gateway show -n $APPGW_NAME -g $RESOURCE_GROUP -o tsv --query "id")
az role assignment create --role "Network Contributor" --scope (az group show -n $RESOURCE_GROUP --query id -o tsv) --assignee $MI_CLIENT_ID

az role assignment create --role Reader --scope $RG_ID --assignee 89ecce7c-7849-4802-9063-ee22b34609d1
az role assignment create --role Contributor --scope $APPGW_ID --assignee 89ecce7c-7849-4802-9063-ee22b34609d1
```

Now you can get the Ingress Controller added to the AKS cluster

```
terraform apply
```

Finally, we need to ensure that the managed identity has the necessary
permissions to manage the Application Gateway.

```
set -x INGRESS_MI (az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query addonProfiles.ingressApplicationGateway.identity.clientId -o tsv)


az role assignment create --role "Contributor" --scope $APPGW_ID --assignee $INGRESS_MI
az role assignment create --role "Owner" --scope "$MI_SCOPE" --assignee $INGRESS_MI
az keyvault set-policy --name pc-test-deploy-secrets --secret-permissions get --object-id (az identity show -n pcc-mi -g pcc-test-rg --query principalId -o tsv)
```

## Additional References

Many of the concepts used here were learned in deployments at the [pangeo-cloud-federation](https://github.com/pangeo-data/pangeo-cloud-federation) and [2i2c pilot hubs](https://github.com/2i2c-org/pilot-hubs). Those might serve as additional references for how to deploy a Hub.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

[gateway]: https://gateway.dask.org/
[jupyterhub]: https://jupyterhub.readthedocs.io/en/stable/
[hub]: https://planetarycomputer.microsoft.com/docs/overview/environment/
[aks]: https://docs.microsoft.com/en-us/azure/aks/
[daskhub]: https://github.com/dask/helm-chart/tree/main/daskhub
[deployment guide]: https://planetarycomputer.microsoft.com/docs/concepts/hub-deployment/
[sp]: https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals
[hub-service]: https://jupyterhub.readthedocs.io/en/stable/reference/services.html
[agic]: https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview