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

########## API ##########

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
}

########## NETWORK ##########

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

########## IDENTITY ##########

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

resource "azurerm_logic_app_workflow" "raw" {
  name                = "logicAppRaw"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  parameters = { "$connections" = jsonencode({
    "${azurerm_api_connection.aci.name}" = {
      connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
      connectionName = "${azurerm_api_connection.aci.name}"
      id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
    }
  }) }
  workflow_parameters = { "$connections" = jsonencode({
    defaultValue = {}
    type         = "Object"
  }) }
}

# https://medium.com/@jan.fiedler/how-to-implement-a-full-terraform-managed-start-stop-scheduling-for-azure-container-instances-with-39f688b334ba
## Define the Trigger
resource "azurerm_logic_app_trigger_recurrence" "raw" {
  name         = "scheduled-start"
  time_zone    = "W. Europe Standard Time"
  logic_app_id = azurerm_logic_app_workflow.raw.id
  frequency    = "Day"
  interval     = 1

  schedule {
    at_these_hours   = [16, 17, 18]
    at_these_minutes = [5, 15, 25, 35, 45, 55]
  }
}

## Define the Action
resource "azurerm_logic_app_action_custom" "raw" {
  name         = "raw-aci"
  logic_app_id = azurerm_logic_app_workflow.raw.id

  body = <<BODY
{
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['${azurerm_api_connection.aci.name}']['connectionId']"
            }
        },
        "method": "post",
        "path": "/subscriptions/@{encodeURIComponent('${var.subscription_id}')}/resourceGroups/@{encodeURIComponent('${azurerm_resource_group.rg.name}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('${azurerm_container_group.raw.name}')}/start",
        "queries": {
            "x-ms-api-version": "2019-12-01"
        }
    },
    "runAfter": {},
    "type": "ApiConnection"
    }
BODY
}



########## ENRICHED CONTAINER GROUP ##########

resource "azurerm_container_group" "enriched" {
  name                = "${var.env}-dp-enriched"
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
    name   = "mocked-enriched"
    image  = "${var.acr_name}.azurecr.io/mocked-enriched:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49152
      protocol = "TCP"
    }
  }
}

resource "azurerm_logic_app_workflow" "enriched" {
  name                = "logicAppenriched"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  parameters = { "$connections" = jsonencode({
    "${azurerm_api_connection.aci.name}" = {
      connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
      connectionName = "${azurerm_api_connection.aci.name}"
      id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
    }
  }) }
  workflow_parameters = { "$connections" = jsonencode({
    defaultValue = {}
    type         = "Object"
  }) }
}

# https://medium.com/@jan.fiedler/how-to-implement-a-full-terraform-managed-start-stop-scheduling-for-azure-container-instances-with-39f688b334ba
## Define the Trigger
resource "azurerm_logic_app_trigger_recurrence" "enriched" {
  name         = "scheduled-start"
  time_zone    = "W. Europe Standard Time"
  logic_app_id = azurerm_logic_app_workflow.enriched.id
  frequency    = "Day"
  interval     = 1

  schedule {
    at_these_hours   = [16, 17, 18]
    at_these_minutes = [5, 15, 25, 35, 45, 55]
  }
}

## Define the Action
resource "azurerm_logic_app_action_custom" "enriched" {
  name         = "enriched-aci"
  logic_app_id = azurerm_logic_app_workflow.enriched.id

  body = <<BODY
{
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['${azurerm_api_connection.aci.name}']['connectionId']"
            }
        },
        "method": "post",
        "path": "/subscriptions/@{encodeURIComponent('${var.subscription_id}')}/resourceGroups/@{encodeURIComponent('${azurerm_resource_group.rg.name}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('${azurerm_container_group.enriched.name}')}/start",
        "queries": {
            "x-ms-api-version": "2019-12-01"
        }
    },
    "runAfter": {},
    "type": "ApiConnection"
    }
BODY
}

resource "azurerm_container_group" "enriched" {
  name                = "${var.env}-dp-enriched"
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
    name   = "mocked-enriched"
    image  = "${var.acr_name}.azurecr.io/mocked-enriched:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49152
      protocol = "TCP"
    }
  }
}

resource "azurerm_logic_app_workflow" "enriched" {
  name                = "logicAppenriched"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  parameters = { "$connections" = jsonencode({
    "${azurerm_api_connection.aci.name}" = {
      connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
      connectionName = "${azurerm_api_connection.aci.name}"
      id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
    }
  }) }
  workflow_parameters = { "$connections" = jsonencode({
    defaultValue = {}
    type         = "Object"
  }) }
}

# https://medium.com/@jan.fiedler/how-to-implement-a-full-terraform-managed-start-stop-scheduling-for-azure-container-instances-with-39f688b334ba
## Define the Trigger
resource "azurerm_logic_app_trigger_recurrence" "enriched" {
  name         = "scheduled-start"
  time_zone    = "W. Europe Standard Time"
  logic_app_id = azurerm_logic_app_workflow.enriched.id
  frequency    = "Day"
  interval     = 1

  schedule {
    at_these_hours   = [1]
    at_these_minutes = [5]
  }
}

## Define the Action
resource "azurerm_logic_app_action_custom" "enriched" {
  name         = "enriched-aci"
  logic_app_id = azurerm_logic_app_workflow.enriched.id

  body = <<BODY
{
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['${azurerm_api_connection.aci.name}']['connectionId']"
            }
        },
        "method": "post",
        "path": "/subscriptions/@{encodeURIComponent('${var.subscription_id}')}/resourceGroups/@{encodeURIComponent('${azurerm_resource_group.rg.name}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('${azurerm_container_group.enriched.name}')}/start",
        "queries": {
            "x-ms-api-version": "2019-12-01"
        }
    },
    "runAfter": {},
    "type": "ApiConnection"
    }
BODY
}


########## CURATED CONTAINER GROUP ##########


resource "azurerm_container_group" "curated" {
  name                = "${var.env}-dp-curated"
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
    name   = "mocked-curated"
    image  = "${var.acr_name}.azurecr.io/mocked-curated:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49152
      protocol = "TCP"
    }
  }
}

resource "azurerm_logic_app_workflow" "curated" {
  name                = "logicAppcurated"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  parameters = { "$connections" = jsonencode({
    "${azurerm_api_connection.aci.name}" = {
      connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
      connectionName = "${azurerm_api_connection.aci.name}"
      id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
    }
  }) }
  workflow_parameters = { "$connections" = jsonencode({
    defaultValue = {}
    type         = "Object"
  }) }
}

# https://medium.com/@jan.fiedler/how-to-implement-a-full-terraform-managed-start-stop-scheduling-for-azure-container-instances-with-39f688b334ba
## Define the Trigger
resource "azurerm_logic_app_trigger_recurrence" "curated" {
  name         = "scheduled-start"
  time_zone    = "W. Europe Standard Time"
  logic_app_id = azurerm_logic_app_workflow.curated.id
  frequency    = "Day"
  interval     = 1

  schedule {
    at_these_hours   = [2]
    at_these_minutes = [5]
  }
}

## Define the Action
resource "azurerm_logic_app_action_custom" "curated" {
  name         = "curated-aci"
  logic_app_id = azurerm_logic_app_workflow.curated.id

  body = <<BODY
{
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['${azurerm_api_connection.aci.name}']['connectionId']"
            }
        },
        "method": "post",
        "path": "/subscriptions/@{encodeURIComponent('${var.subscription_id}')}/resourceGroups/@{encodeURIComponent('${azurerm_resource_group.rg.name}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('${azurerm_container_group.curated.name}')}/start",
        "queries": {
            "x-ms-api-version": "2019-12-01"
        }
    },
    "runAfter": {},
    "type": "ApiConnection"
    }
BODY
}

resource "azurerm_container_group" "curated" {
  name                = "${var.env}-dp-curated"
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
    name   = "mocked-curated"
    image  = "${var.acr_name}.azurecr.io/mocked-curated:dev"
    cpu    = 1
    memory = 2
    ports {
      port     = 49152
      protocol = "TCP"
    }
  }
}

resource "azurerm_logic_app_workflow" "curated" {
  name                = "logicAppcurated"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  workflow_schema = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version = "1.0.0.0"

  parameters = { "$connections" = jsonencode({
    "${azurerm_api_connection.aci.name}" = {
      connectionId   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Web/connections/${azurerm_api_connection.aci.name}"
      connectionName = "${azurerm_api_connection.aci.name}"
      id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.rg.location}/managedApis/aci"
    }
  }) }
  workflow_parameters = { "$connections" = jsonencode({
    defaultValue = {}
    type         = "Object"
  }) }
}

# https://medium.com/@jan.fiedler/how-to-implement-a-full-terraform-managed-start-stop-scheduling-for-azure-container-instances-with-39f688b334ba
## Define the Trigger
resource "azurerm_logic_app_trigger_recurrence" "curated" {
  name         = "scheduled-start"
  time_zone    = "W. Europe Standard Time"
  logic_app_id = azurerm_logic_app_workflow.curated.id
  frequency    = "Day"
  interval     = 1

  schedule {
    at_these_hours   = [3]
    at_these_minutes = [5]
  }
}

## Define the Action
resource "azurerm_logic_app_action_custom" "curated" {
  name         = "curated-aci"
  logic_app_id = azurerm_logic_app_workflow.curated.id

  body = <<BODY
{
    "inputs": {
        "host": {
            "connection": {
                "name": "@parameters('$connections')['${azurerm_api_connection.aci.name}']['connectionId']"
            }
        },
        "method": "post",
        "path": "/subscriptions/@{encodeURIComponent('${var.subscription_id}')}/resourceGroups/@{encodeURIComponent('${azurerm_resource_group.rg.name}')}/providers/Microsoft.ContainerInstance/containerGroups/@{encodeURIComponent('${azurerm_container_group.curated.name}')}/start",
        "queries": {
            "x-ms-api-version": "2019-12-01"
        }
    },
    "runAfter": {},
    "type": "ApiConnection"
    }
BODY
}

