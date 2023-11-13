# #!/bin/bash
# # Command to get credentials
# output=$(az acr credential show -n devdpvulrf19)

# # Parse the JSON output to extract the username and first password
# username=$(echo "$output" | jq -r '.username')
# first_password=$(echo "$output" | jq -r '.passwords[0].value')


# # Set variables
# identityName="${var.env}-managed-identity"
# resourceGroup="${var.rg_name}" # Ensure this is set to your resource group name
# acrId=$(az acr show --name ${var.acr_name} --query id --output tsv)

# # Create a managed identity
# az identity create --name "$identityName" --resource-group "$resourceGroup"

# # Get the managed identity ID
# identityId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query id --output tsv)

# # Assign the AcrPull role to the managed identity for your ACR
# az role assignment create --assignee "$identityId" --role "AcrPull" --scope "$acrId"

# # Output the managed identity ID and principal ID for use in Terraform
# principalId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query principalId --output tsv)
# echo "Managed Identity ID: $identityId"
# echo "Managed Identity Principal ID: $principalId"
#!/bin/bash

# Set variables
identityName="dev-managed-identity"
resourceGroup="${var.rg_name}" # Ensure this is set to your resource group name
acrId=$(az acr show --name ${var.acr_name} --query id --output tsv)

# Create a managed identity
az identity create --name "$identityName" --resource-group "$resourceGroup"

# Get the managed identity ID
identityId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query id --output tsv)

# Assign the AcrPull role to the managed identity for your ACR
az role assignment create --assignee "$identityId" --role "AcrPull" --scope "$acrId"

# Output the managed identity ID and principal ID for use in Terraform
principalId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query principalId --output tsv)
echo "Managed Identity ID: $identityId"
echo "Managed Identity Principal ID: $principalId"
