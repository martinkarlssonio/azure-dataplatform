## This script is used to run the deployment process on a Windows machine.
## It will build the base image, deploy the core resources, build the containers and push them to ACR, and finally deploy the containers.

Write-Host "######################################## EXECUTION STARTING ########################################"
$env = "dev"
Remove-Item -Recurse -Force "output" -ErrorAction SilentlyContinue

Write-Host "################# Please log in so we have correct permissions to deploy"
az login
# Copy-Item -Path "$HOME\.azure" -Destination ".\.azure" -Recurse -Force

########################## BASE DEPLOY IMAGE
Write-Host "################# Building base image"
Set-Location "base-deploy-image"
docker build . -t deploy-image
Set-Location ..

########################## REMOVE ANY OLD CONTAINERS
Write-Host "################# Removing old deployment-container and live-deploy image"
$containerId = docker ps -a | Where-Object { $_ -match 'deploy-container' } | ForEach-Object { ($_ -split '\s+')[0] }
Write-Output $containerId
if (-not [string]::IsNullOrEmpty($containerId)) {
    docker rm $containerId
} else {
    Write-Output "No 'deploy-container' found to remove."
}
Start-Sleep -Seconds 10

$imageId = docker images | Where-Object { $_ -match 'live-deploy' } | ForEach-Object { ($_ -split '\s+')[2] }
Write-Output $imageId
if (-not [string]::IsNullOrEmpty($imageId)) {
    docker rmi $imageId
} else {
    Write-Output "No 'live-deploy' image found to remove."
}

Start-Sleep -Seconds 10

########################## DEPLOY CORE RESOURCES
Write-Host "################# Building deployment image"
docker build . -t live-deploy
Start-Sleep -Seconds 10

Write-Host "################# Deploying core"
docker run --name deploy-container -v "$(Get-Location)/output:/output" -e "PHASE=core" -e "TF_VAR_env=$env" live-deploy

Start-Sleep -Seconds 10

Write-Host "################# Removing deploy-container"
$containerId = docker ps -a | Where-Object { $_ -match 'deploy-container' } | ForEach-Object { ($_ -split '\s+')[0] }
Write-Output $containerId
if (-not [string]::IsNullOrEmpty($containerId)) {
    docker rm $containerId
} else {
    Write-Output "No 'deploy-container' found to remove."
}

Start-Sleep -Seconds 10

########################## BUILD DOCKER IMAGES AND PUSH TO ACR
Write-Host "################# Building and pushing containers to ACR"
# Save current location
Push-Location
# Change the location to 'containers' directory
Set-Location "containers"

# Print the current location
Write-Host $(Get-Location)

# Run the other PowerShell script
Invoke-Expression -Command .\winPushContAcr.ps1
Start-Sleep -Seconds 10
Write-Host "################# Deploying containers"
# Go back to original directory
Pop-Location
Write-Host $(Get-Location)
Start-Sleep -Seconds 10

########################## DEPLOY CONTAINERS RESOURCES
docker run --name deploy-container -v "$(Get-Location)/output:/output" -e "PHASE=containers" -e "TF_VAR_env=$env" live-deploy

Write-Host "################# Removing deploy-container"
Start-Sleep -Seconds 5
$containerId = docker ps -a | Where-Object { $_ -match 'deploy-container' } | ForEach-Object { ($_ -split '\s+')[0] }
Write-Output $containerId
if (-not [string]::IsNullOrEmpty($containerId)) {
    docker rm $containerId
} else {
    Write-Output "No 'deploy-container' found to remove."
}

## Delete output folder
$folderPath = "output"
if (Test-Path $folderPath) {
    Remove-Item $folderPath -Recurse -Force
} else {
    Write-Host "Folder 'output' does not exist."
}

Write-Host "################# DEPLOYMENT COMPLETED #################"
