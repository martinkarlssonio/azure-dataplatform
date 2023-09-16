terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}
provider "azurerm" { 
  skip_provider_registration = "true"
  subscription_id = "${var.subscription_id}"  
  client_id       = "${var.arm_client_id}"  
  client_secret   = "${var.arm_client_secret}"  
  tenant_id       = "${var.arm_tenant_id}" 
  features {}
}