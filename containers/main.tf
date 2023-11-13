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

# ########## CONTAINER SCHEDULER CONTAINER GROUP ##########
# resource "azurerm_container_group" "container-scheduler" {
#   name                = "${var.env}-container-scheduler"
#   location            = "${var.rg_location}"
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_address_type     = "Private"
#   subnet_ids          = [azurerm_subnet.containers.id]
#   os_type             = "Linux"
#   restart_policy      = "Never" #"OnFailure"

#   image_registry_credential {
#     #username = "00000000-0000-0000-0000-000000000000"  # username when using access token
#     #password = "${var.acr_access_token}"               # Use the access token here
#     username = "${var.acr_username}"
#     password = "${var.acr_password}"
#     server   = "${var.acr_name}.azurecr.io"
#   }

#   container {
#     name   = "container-scheduler"
#     image  = "${var.acr_name}.azurecr.io/container-scheduler:dev"
#     cpu    = 0.1
#     memory = 0.1
#     ports {
#       port     = 49151
#       protocol = "TCP"
#     }
#   }
# }

########## RAW CONTAINER GROUP ##########
# resource "azurerm_container_group" "raw" {
#   name                = "${var.env}-dp-raw"
#   location            = "${var.rg_location}"
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_address_type     = "Private"
#   subnet_ids          = [azurerm_subnet.containers.id]
#   os_type             = "Linux"
#   restart_policy      = "Never" #"OnFailure"

#   image_registry_credential {
#     #username = "00000000-0000-0000-0000-000000000000"  # username when using access token
#     #password = "${var.acr_access_token}"               # Use the access token here
#     username = "${var.acr_username}"
#     password = "${var.acr_password}"
#     server   = "${var.acr_name}.azurecr.io"
#   }

#   container {
#     name   = "mocked-raw"
#     image  = "${var.acr_name}.azurecr.io/mocked-raw:dev"
#     cpu    = 1
#     memory = 2
#     ports {
#       port     = 49152
#       protocol = "TCP"
#     }
#   }
# }


resource "azurerm_container_group" "raw" {
  name                = "${var.env}-dp-raw"
  location            = "${var.rg_location}"
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.containers.id]
  os_type             = "Linux"
  restart_policy      = "Never" #"OnFailure"

  image_registry_credential {
    #username = "00000000-0000-0000-0000-000000000000"  # username when using access token
    #password = "${var.acr_access_token}"               # Use the access token here
    username = "${var.acr_username}"
    password = "${var.acr_password}"
    server   = "${var.acr_name}.azurecr.io"
  }

  # Assign an identity
  identity {
    type = "SystemAssigned"
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

# Create an identity for the logic app
resource "azurerm_user_assigned_identity" "logic_app" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.rg_location
  name                = "logic_app"
}

# Assign the identity access to ACR
resource "azurerm_role_assignment" "logic_app" {
  scope                = "/subscriptions/${var.subscription_id}" #/resourceGroups/${var.env}-dataplatform-core/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
  role_definition_name = "owner"
  principal_id         = azurerm_user_assigned_identity.logic_app.principal_id
}

resource "azurerm_logic_app_workflow" "logicAppRaw" {
  name                = "logicAppRaw"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  # parameters = {
  #     "actions" = jsonencode({
  #       Start_containers_in_a_container_group = {
  #         inputs = {
  #           host = {
  #             connection = {
  #               name = "@parameters('$connections')['aci']['connectionId']"
  #             }
  #           },
  #           method = "post",
  #           path = "/subscriptions/@{encodeURIComponent('1d4234cf-2e23-4600-897e-300f194cae95')}/resourceGroups/@{encodeURIComponent('dev-dataplatform-container')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('dev-dp-raw')}/start",
  #           queries = {
  #             "x-ms-api-version" = "2019-12-01"
  #           }
  #         },
  #         runAfter = {},
  #         type = "ApiConnection"
  #       }
  #     }),
  #     "triggers" = jsonencode({
  #       Recurrence = {
  #         evaluatedRecurrence = {
  #           frequency = "Minute",
  #           interval = 20
  #         },
  #         recurrence = {
  #           frequency = "Minute",
  #           interval = 20
  #         },
  #         type = "Recurrence"
  #       }
  #     }),
  #   "$connections" = jsonencode({
  #       "aci" = {
  #         connectionId = "/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95/resourceGroups/dev-dataplatform-container/providers/Microsoft.Web/connections/aci",
  #         connectionName = "aci",
  #         connectionProperties = {
  #           authentication = {
  #             identity = "/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95/resourceGroups/dev-dataplatform-container/providers/Microsoft.ManagedIdentity/userAssignedIdentities/logic_app",
  #             type = "ManagedServiceIdentity"
  #           }
  #         },
  #         id = "/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95/providers/Microsoft.Web/locations/germanywestcentral/managedApis/aci"
  #       }
  #   })
  # }
}

# resource "azurerm_logic_app_workflow" "raw" {
#   name                = "logicAppRaw"
#   location            = var.rg_location
#   resource_group_name = azurerm_resource_group.rg.name

#   identity {
#     type = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.logic_app.id]
#   }

#   parameters = { "$connections" = jsonencode({
#     "${azurerm_api_connection.aci.name}" = {
#       connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
#       connectionName = "${azurerm_api_connection.aci.name}"
#       id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
#     }
#   }) }
#   workflow_parameters = { "$connections" = jsonencode({
#     defaultValue = {}
#     type         = "Object"
#   }) }
# }


## API Connection (used by Logic Apps to trigger Container Groups)
# https://learn.microsoft.com/en-us/connectors/custom-connectors/faq
data "azurerm_managed_api" "aci" {
  name     = "aci"
  location = azurerm_resource_group.rg.location
}

resource "azurerm_api_connection" "aci" {
  name                = "aci"
  resource_group_name = azurerm_resource_group.rg.name
  managed_api_id      = data.azurerm_managed_api.aci.id
  display_name        = "aci"

  # parameter_values = {
  #   "managedIdentityAuth" = jsonencode({})
  # }
}


# resource "null_resource" "create_web_connection" {
#   provisioner "local-exec" {
#     command = <<EOT
#       az resource create \
#       --resource-type "Microsoft.Web/connections" \
#       --name "aci" \
#       --resource-group "${var.env}-dataplatform-container" \
#       --location ${var.rg_location} \
#       --properties '{ \
#         "displayName": "aci", \
#         "api": { \
#           "id": "subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/germanywestcentral/managedApis/aci" \
#         } \
#       }'
#     EOT
#   }
# }



# #### ENRICHED
# resource "azurerm_container_group" "enriched" {
#   name                = "${var.env}-dp-enriched"
#   location            = "${var.rg_location}"
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_address_type     = "Private"
#   subnet_ids          = [azurerm_subnet.containers.id]
#   os_type             = "Linux"
#   restart_policy      = "Never" #"OnFailure"
  
#   image_registry_credential {
#     username = "00000000-0000-0000-0000-000000000000"  # username when using access token
#     password = "${var.acr_access_token}"               # Use the access token here
#     server   = "${var.acr_name}.azurecr.io"
#   }

#   container {
#     name   = "mocked-enriched"
#     image  = "${var.acr_name}.azurecr.io/mocked-enriched:dev"
#     cpu    = 1
#     memory = 2
#     ports {
#       port     = 49153
#       protocol = "TCP"
#     }
#   }
# }


# #### CURATED
# resource "azurerm_container_group" "curated" {
#   name                = "${var.env}-dp-curated"
#   location            = "${var.rg_location}"
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_address_type     = "Private"
#   subnet_ids          = [azurerm_subnet.containers.id]
#   os_type             = "Linux"
#   restart_policy      = "Never" #"OnFailure"
  
#   image_registry_credential {
#     username = "00000000-0000-0000-0000-000000000000"  # username when using access token
#     password = "${var.acr_access_token}"               # Use the access token here
#     server   = "${var.acr_name}.azurecr.io"
#   }
#   container {
#     name   = "mocked-curated"
#     image  = "${var.acr_name}.azurecr.io/mocked-curated:dev"
#     cpu    = 1
#     memory = 2
#     ports {
#       port     = 49154
#       protocol = "TCP"
#     }
#   }
# }
