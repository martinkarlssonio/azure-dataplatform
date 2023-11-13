# https://learn.microsoft.com/en-us/azure/container-instances/container-instances-managed-identity

## Create an Azure key vault
az group create --name myResourceGroup --location eastus
az keyvault create --name mykeyvault93kj --resource-group myResourceGroup --location eastus
az keyvault secret set --name SampleSecret --value "Hello Container Instances" --description ACIsecret --vault-name mykeyvault


### Use a system-assigned identity to access Azure key vault
## Enable system-assigned identity on a container group
# Get the resource ID of the resource group
RG_ID=$(az group show --name myResourceGroup --query id --output tsv)

# Create container group with system-managed identity
az container create --resource-group myResourceGroup --name mycontainer --image mcr.microsoft.com/azure-cli --assign-identity --scope $RG_ID --command-line "tail -f /dev/null"
az container show --resource-group myResourceGroup --name mycontainer
SP_ID=$(az container show --resource-group myResourceGroup --name mycontainer --query identity.principalId --out tsv)

# Grant container group access to the key vault
az keyvault set-policy --name mykeyvault93kj --resource-group myResourceGroup --object-id $SP_ID --secret-permissions get

# Use container group identity to get secret from key vault
az container exec --resource-group myResourceGroup --name mycontainer --exec-command "/bin/bash"
az login --identity
az keyvault secret show --name SampleSecret --vault-name mykeyvault93kj --query value
