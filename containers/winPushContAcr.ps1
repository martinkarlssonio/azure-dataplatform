# Load variables from .envTf
Write-Output "Start"
Copy-Item -Path "../output/.envTf" -Destination ".envTf"
Copy-Item -Path "../output/.envBlob" -Destination ".env"
Write-Output "Loading env variables"

$envTfPath = (Get-Location).Path + "\.envTf"
Write-Output $envTfPath
Get-Content .envTf | ForEach-Object {
    if ($_ -match '^(.+?)=(.+)$') {
        $name = $matches[1]
        $value = $matches[2]
        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# Define the environment variables
$tenantId = $env:TF_VAR_arm_tenant_id
$clientId = $env:TF_VAR_arm_client_id
$clientSecret = $env:TF_VAR_arm_client_secret

# Login to Azure
az login `
--service-principal `
--tenant $tenantId `
--username $clientId `
--password $clientSecret `
--output table

Start-Sleep -Seconds 5
# Verify if variables are loaded
Write-Output "TF_VAR_arm_client_id: $env:TF_VAR_arm_client_id"
Write-Output "TF_VAR_arm_client_secret: $env:TF_VAR_arm_client_secret"

az acr login --name $env:TF_VAR_acr_name --username "$env:TF_VAR_arm_client_id" --password "$env:TF_VAR_arm_client_secret"
Start-Sleep -Seconds 2

# Fetch all Container Repositories in ACR
$repositories = az acr repository list --name $env:TF_VAR_acr_name | ConvertFrom-Json

# Initialize an empty array to store existing images
$images = @()
foreach ($repository in $repositories) {
    # List all the tags for each repository
    $tags = az acr repository show-tags --name $env:TF_VAR_acr_name --repository $repository | ConvertFrom-Json
    foreach ($tag in $tags) {
        $image = "${repository}:${tag}"
        $images += $image
    }
}

## Function that will push new images to Container Registry
function Process-Image {
    param (
        [string]$imageName,
        [string]$tag
    )
    $combinedName = "${imageName}:${tag}"
    if ($images -contains $combinedName) {
        Write-Host "$combinedName already exists in container registry"
    } else {
        Write-Host "Pushing $combinedName to container registry"
        Copy-Item -Path ".env" -Destination "${imageName}\\.env"
        Copy-Item -Path "../output/coreOutput.json" -Destination "${imageName}\\coreOutput.json"
        Start-Sleep -Seconds 5
        Set-Location "${imageName}"
        docker build -t "${combinedName}" .
        Start-Sleep -Seconds 5
        docker images
        docker tag "${combinedName}" "$env:TF_VAR_acr_name.azurecr.io/${combinedName}"
        docker push "$env:TF_VAR_acr_name.azurecr.io/${combinedName}"
        Set-Location ..
    }
}

###################### IMAGES TO PROCESS
## If you want to release a new version of an image, do not forget to change the tag both here and in terraform.
Process-Image -imageName "mocked-raw" -tag "dev"
Process-Image -imageName "mocked-enriched" -tag "dev"
Process-Image -imageName "mocked-curated" -tag "dev"