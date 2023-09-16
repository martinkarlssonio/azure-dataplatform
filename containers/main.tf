resource "random_string" "random_suffix" {
  length  = 7
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.env}-dataplatform-container"
  location = "${var.rg_location}"
}

# Create a virtual network
resource "azurerm_virtual_network" "containers" {
  name                = "${var.env}dpvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.rg_location}"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a subnet in the virtual network
resource "azurerm_subnet" "containers" {
  name                 = "${var.env}dpvnsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.containers.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "${var.env}dpvsubnetdelegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}


########## RAW CONTAINER GROUP ##########


resource "azurerm_container_group" "raw" {
  name                = "${var.env}-dp-raw"
  location            = "${var.rg_location}"
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.containers.id]
  os_type             = "Linux"
  restart_policy      = "Never" #"OnFailure"
  
  image_registry_credential {
    username = "${var.arm_client_id}"
    password = "${var.arm_client_secret}"
    server   = "${var.acr_name}.azurecr.io"
  }

  container {
    name   = "mocked-raw"
    image  = "${var.acr_name}.azurecr.io/mocked-raw:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49152
      protocol = "TCP"
    }
  }
}

#### ENRICHED
resource "azurerm_container_group" "enriched" {
  name                = "${var.env}-dp-enriched"
  location            = "${var.rg_location}"
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.containers.id]
  os_type             = "Linux"
  restart_policy      = "Never" #"OnFailure"
  
  image_registry_credential {
    username = "${var.arm_client_id}"
    password = "${var.arm_client_secret}"
    server   = "${var.acr_name}.azurecr.io"
  }

  container {
    name   = "mocked-enriched"
    image  = "${var.acr_name}.azurecr.io/mocked-enriched:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49153
      protocol = "TCP"
    }
  }
}


#### CURATED
resource "azurerm_container_group" "curated" {
  name                = "${var.env}-dp-curated"
  location            = "${var.rg_location}"
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.containers.id]
  os_type             = "Linux"
  restart_policy      = "Never" #"OnFailure"
  
  image_registry_credential {
    username = "${var.arm_client_id}"
    password = "${var.arm_client_secret}"
    server   = "${var.acr_name}.azurecr.io"
  }

  container {
    name   = "mocked-curated"
    image  = "${var.acr_name}.azurecr.io/mocked-curated:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49154
      protocol = "TCP"
    }
  }
}
