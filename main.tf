########################################################################################################################
# Resource group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# IBM Verify instance
########################################################################################################################

module "isv_instance" {
  source  = "terraform-ibm-modules/security-verify/ibm"
  version = "1.1.1"

  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  instance_name     = var.instance_name
  hostname          = var.hostname
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
}

# Generate service credentials for the IBM Verify instance
resource "ibm_resource_key" "verify_credentials" {
  name                 = "${var.instance_name}-credentials"
  resource_instance_id = module.isv_instance.guid
  role                 = "Administrator"
  
  # Valid roles for IBM Verify:
  # NONE, Service Configuration Reader, Viewer, Administrator, Operator, Editor, Key Manager
}

# Parse the credentials and construct URLs
locals {
  credentials      = jsondecode(ibm_resource_key.verify_credentials.credentials_json)
  dashboard_url    = module.isv_instance.account_url
  account_url      = "https://${var.hostname}.verify.ibm.com"
  verify_base_url  = "${var.hostname}.verify.ibm.com"
  api_access_url   = "${module.isv_instance.account_url}security/api-access"
}

# Write configuration to .env file
resource "local_file" "env_file" {
  content = templatefile("${path.module}/templates/env.tpl", {
    verify_hostname    = local.verify_base_url
    verify_tenant_id   = try(local.credentials.tenantId, "")
    verify_client_id   = try(local.credentials.clientId, "")
    verify_secret      = try(local.credentials.secret, "")
    verify_oauth_url   = try(local.credentials.oAuthServerUrl, "")
    verify_mgmt_url    = try(local.credentials.managementUrl, "")
    verify_instance_id = module.isv_instance.guid
    verify_dashboard   = local.dashboard_url
    verify_account_url = local.account_url
    verify_api_access  = local.api_access_url
  })
  filename = var.env_file_path

  # Update file only if content changes
  file_permission = "0644"
}

