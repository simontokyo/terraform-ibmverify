# Mandatory input parameters aligned with terraform-ibm-modules/security-verify/ibm

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key for authentication"
  type        = string
  sensitive   = true
}

variable "resource_group" {
  description = "The name of an existing resource group to use (or null to create a new one with prefix)"
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix for naming resources (used if creating new resource group)"
  type        = string
  default     = "verify"
}

variable "region" {
  description = "IBM Cloud region where the IBM Verify instance will be deployed (must be eu-de)"
  type        = string
  default     = "eu-de"
  
  validation {
    condition     = var.region == "eu-de"
    error_message = "IBM Verify is only available in the eu-de (Frankfurt) region."
  }
}

variable "instance_name" {
  description = "The name of the IBM Verify instance"
  type        = string
}

variable "hostname" {
  description = "The hostname of the IBM Verify instance (used to construct the Dashboard URL: https://<hostname>.verify.ibm.com/ui/admin/)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.hostname))
    error_message = "Hostname must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

# Optional parameters with sensible defaults

variable "resource_tags" {
  description = "A list of tags to apply to resources created by the module"
  type        = list(string)
  default     = []
}

variable "access_tags" {
  description = "A list of access tags to apply to the resources created by the module"
  type        = list(string)
  default     = []
}

variable "env_file_path" {
  description = "Path where the .env file will be generated"
  type        = string
  default     = ".env"
}

