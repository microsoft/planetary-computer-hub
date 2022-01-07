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

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version. Used in `aks.tf` in several places."
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

variable "pyspark_image" {
  type        = string
  description = "The tag for the PySpark environment image."
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

variable "enable_role_based_access_control" {
  type        = bool
  default     = true
  description = "Enable Role Based Access Control."
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

variable "kbatch_proxy_url" {
  type        = string
  description = "URL (possibly kubernetes-internal) to the kbatch-server application."
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
}
