# Resource group outputs
output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.resource_group.resource_group_id
}

# Core instance outputs
output "instance_name" {
  description = "The name of the IBM Verify instance"
  value       = module.isv_instance.isv_instance_name
}

output "guid" {
  description = "The GUID of the IBM Verify instance"
  value       = module.isv_instance.guid
}

output "crn" {
  description = "The CRN of the IBM Verify instance"
  value       = module.isv_instance.crn
}

# URL outputs
output "hostname" {
  description = "The hostname of the IBM Verify instance"
  value       = local.verify_base_url
}

output "verify_dashboard_url" {
  description = "The IBM Verify dashboard URL"
  value       = local.dashboard_url
}

output "verify_account_url" {
  description = "The IBM Verify account URL"
  value       = local.account_url
}

output "verify_api_access_url" {
  description = "The URL to manage API clients for REST API automation"
  value       = local.api_access_url
}

# Credential outputs

output "tenant_id" {
  description = "The tenant ID of the IBM Verify instance"
  value       = try(local.credentials.tenantId, "")
  sensitive   = true
}

output "client_id" {
  description = "The client ID for authentication"
  value       = try(local.credentials.clientId, "")
  sensitive   = true
}

output "oauth_server_url" {
  description = "The OAuth server URL"
  value       = try(local.credentials.oAuthServerUrl, "")
}

output "management_url" {
  description = "The management URL"
  value       = try(local.credentials.managementUrl, "")
}

# Environment file location
output "env_file_path" {
  description = "Path to the generated .env file"
  value       = local_file.env_file.filename
}

