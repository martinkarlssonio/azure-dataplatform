resource "random_string" "random_suffix" {
  length  = 7
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.env}-dataplatform-core"
  location = "germanywestcentral"
}

resource "azurerm_storage_account" "stacc" {
  name                     = "${var.env}dp${random_string.random_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "${var.env}"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.env}dp${random_string.random_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}
