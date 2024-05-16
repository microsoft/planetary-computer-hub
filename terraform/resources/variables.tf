# ----------------------------------------------------------------------------
# Global

variable "environment" {
  type        = string
  description = "Whether this is a staging or production deployment."
}

variable "region" {
  type        = string
  description = "The Azure region to deploy in. We choose 'West Europe' to match the data."
}

variable "version_number" {
  type        = string
  description = "The revisoin number of this deployment. Useful for migrating between AKS clusters."
  default     = ""
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version. Used in `aks.tf` in several places."
}

variable "aks_azure_active_directory_role_based_access_control" {
  type        = bool
  description = "Whether to enabled managed Azure AD integration."
}

variable "aks_automatic_channel_upgrade" {
  type        = string
  description = "automatic_channel_upgrade"
}


variable "oauth_host" {
  type        = string
  description = "The hostname of the oauth2 provider."
}

variable "jupyterhub_host" {
  type        = string
  description = "The hostname (no protocol, no hub prefix) for JupyterHub."
}

variable "stac_url" {
  type        = string
  description = "The URL for the STAC endpoint (staging, production)"
}

variable "dns_label" {
  type        = string
  description = "Used to acquire a DNS name on .westeurope.cloudapp.azure.com"
}

variable "jupyterhub_singleuser_image_name" {
  type        = string
  description = "The image name (including container registry) for the default singleuser image."
}

variable "jupyterhub_singleuser_image_tag" {
  type        = string
  description = "The tag for the default singleuser image."
}

variable "python_image" {
  type        = string
  description = "The tag for the python environment image."
}

variable "r_image" {
  type        = string
  description = "The tag for the R environment image."
}

variable "gpu_pytorch_image" {
  type        = string
  description = "The tag for the GPU-pytorch environment image."
}

variable "gpu_tensorflow_image" {
  type        = string
  description = "The tag for the GPU-tensorflow environment image."
}


variable "qgis_image" {
  type        = string
  description = "The tag for the QGIS environment image."
}

variable "apim_resource_id" {
  type        = string
  description = "The resource ID for the API Management service."
}

# ----------------------------------------------------------------------------
# AKS

variable "user_vm_size" {
  type = string
  # VM with 64G of RAM, 8 cores, and ssd base disk
  default     = "Standard_E8s_v3"
  description = "The VM size to use for the 'cpu_user' AKS nodepool."
}

variable "core_vm_size" {
  type        = string
  description = "The VM size to use for the default / core AKS nodepool."
}

variable "core_os_disk_type" {
  type        = string
  description = "The disk for staging. Smaller VMs must use 'Managed'."
}

variable "user_pool_min_count" {
  type        = number
  description = "The minimum number of workers for the CPU user nodepool."
}

variable "cpu_worker_pool_min_count" {
  type        = number
  description = "The minimum number of workers for the CPU user nodepool."
}

variable "cpu_worker_vm_size" {
  type = string
  # VM with = 64GB of RAM, 8 cores, and ssd base disk
  default     = "Standard_E8_v3"
  description = "The VM size to use for the 'cpu_worker' AKS nodepool."
}

variable "cpu_worker_max_count" {
  type        = number
  default     = 100
  description = "The maximum number of CPU worker nodes."
}

variable "workspace_id" {
  type        = string
  description = "A random (unique) string to use for the Log Analystics workspace."
}

# ----------------------------------------------------------------------------
# Deploy values

variable "pc_resources_rg" {
  type        = string
  default     = "pc-manual-resources"
  description = "The resource group used for pre-configured values (e.g. Azure Key Vault secrets)."
}

variable "pc_resources_kv" {
  type        = string
  default     = "pc-deploy-secrets"
  description = "The Azure Key Vault name with pre-configured values."
}

variable "user_placeholder_replicas" {
  type        = number
  default     = 0
  description = "The number of User placeholder replicas for JupyterHub (see https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/optimization.html#scaling-up-in-time-user-placeholders)."
}


variable "maybe_versioned_prefix" {
  type        = string
  description = "Temporary hack"
}

# -----------------
# Local variables

locals {
  stack_id          = "pcc"
  location          = lower(replace(var.region, " ", ""))
  prefix            = "${local.stack_id}-${local.location}"
  namespaced_prefix = "${local.stack_id}-${var.environment}"
  # maybe_staging_prefix is "pcc-staging" for staging, and "pcc" for prod
  maybe_staging_prefix = var.environment == "staging" ? local.namespaced_prefix : local.prefix

  is_prod = var.environment == "prod"
  is_v1   = var.version_number == ""

  # maybe_versioned_prefix is
  #   - "pcc" for prod
  #   - "pcc-staging" for staging
  #   - "pcc-staging-2" for staging v2
  #   - "pcc-prod-2" for staging v2
  # maybe_versioned_prefix = var.version_number == "" && var.environment == "prod" ? local.prefix : "${local.maybe_staging_prefix}-${var.version_number}"
  # maybe_versioned_prefix = "${coalesce}"

  helm_release_name = "dhub-${var.environment}"
}
