terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.79.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

