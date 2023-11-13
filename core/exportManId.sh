identityId="/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95/resourcegroups/dev-dataplatform-core/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dev-managed-identity"
subId="/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95"
az role assignment create --assignee "$identityId" --role "owner" --scope "/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95"
# #!/bin/bash
# TF_VAR_rg_name="dev-dataplatform-core"
# TF_VAR_acr_name="devdpng4fg4b"
# # Set variables
# identityName="dev-managed-identity"
# resourceGroup="${TF_VAR_rg_name}" # Ensure this is set to your resource group name
# acrId=$(az acr show --name ${TF_VAR_acr_name} --query id --output tsv)

# # Create a managed identity
# identityResponse=$(az identity create --name "$identityName" --resource-group "$resourceGroup")
# identityId=$(echo $identityResponse | jq -r '.id')
# principalId=$(echo $identityResponse | jq -r '.principalId')

# # # Get the managed identity ID
# # identityId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query id --output tsv)

# # Assign the AcrPull role to the managed identity for your ACR
# #az role assignment create --assignee "$identityId" --role "AcrPull" --scope "$acrId"
# identityId="/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95/resourcegroups/dev-dataplatform-core/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dev-managed-identity"
# subId="/subscriptions/1d4234cf-2e23-4600-897e-300f194cae95"
# az role assignment create --assignee "$identityId" --role "owner" --scope "$subId"

# # # Output the managed identity ID and principal ID for use in Terraform
# # principalId=$(az identity show --name "$identityName" --resource-group "$resourceGroup" --query principalId --output tsv)
# echo "Managed Identity ID: $identityId"
# echo "Managed Identity Principal ID: $principalId"

# export TF_VAR_man_id=${identityId}
# echo $TF_VAR_man_id > /output/man_id
# export TF_VAR_man_prin_id=${principalId}
# echo $TF_VAR_man_prin_id > /output/man_prin_id