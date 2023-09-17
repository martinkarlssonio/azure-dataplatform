# Containerized Azure Dataplatform
### A cost-efficient, containerized Azure Dataplatform with Azure Container Instance, Azure Container Registry, Azure Logic App and Azure Blob Storage. Local compute for data exploration in Jupyter Notebook.

<!--
*** Written by Martin Karlsson
*** www.martinkarlsson.io
-->

[![LinkedIn][linkedin-shield]][linkedin-url]

## Architecture

#### Cloud Architecture
Built around Azure Container Instance, Azure Container Registry, Azure Logic App and Azure Blob Storage.
![Architecture overview][arch]

#### Deployment Architecture
The deployment is done as much as possible with containers to ensure consistency on different machines. Building and pushing container images to Azure Container Registry will be done outside container.
![Deployment architecture overview][depArch]

## Prerequisite
#### Install Terraform 
https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli

##### Linux (Fedora)
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf -y install terraform

##### Windows
1. Install chocolatey (https://chocolatey.org/install#individual)
Execute in administrative shell.

        If `Get-ExecutionPolicy` returns **Restricted** then execute : `Set-ExecutionPolicy AllSigned`
    Proceed with:

        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

2. Install terraform

        choco install terraform

#### Install Azure CLI
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
##### Linux (Fedora)
    sudo dnf install azure-cli

##### Windows
64bit

    https://aka.ms/installazurecliwindowsx64
32bit

    https://aka.ms/installazurecliwindows

#### Install Docker
##### Linux (Fedora)
https://docs.docker.com/desktop/install/linux-install/

##### Windows
https://docs.docker.com/desktop/install/windows-install/#install-docker-desktop-on-windows

You might be requested to update WSL, do that with below command in PowerShell:
    
    wsl --update

#### Active subscription
Ensure there is an active subscription configured in the Azure account. The deployment will fetch the subscriptions and take the first response and use that.

#### Roles and Credentials
The script will create two roles on this subscription, `Owner` and `Storage Blob Data Contributor`.
The `Owner` role will be used for deployment while the `Storage Blob Data Contributor` will be used inside the containers to read/write data to Blob.

All the credentials will be automatically exported in the script to .env files, later used when deploying the infrastructure.


#### Verify deployment
After Execution the deployment should be possible to see at https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups


## Deploy
#### Linux (Terminal)
    bash linuxRun.sh
#### Windows (PowerShell)
    ./winRun.ps1

## Edit and update the solution
#### Add more containers
1. Create a new folder under `containers/`, e.g. `my-new-container`.
2. Add all your necessary files and Dockerfile inside this new folder.
3. Edit `containers/main.tf` and add a new container object under any of the container groups (raw, enriched or curated). Allocate a non-used port.

        container {
        name   = "my-new-container"
        image  = "${var.acr_name}.azurecr.io/my-new-container:dev"
        cpu    = 1
        memory = 2
        ports {
            port     = 20xx
            protocol = "TCP"
            }
        }

4. Edit `containers/linuxPushContAcr.sh` and/or `containers/winPushContAcr.ps1` and add so it builds and pushes an image to ACR.

###### linuxPushContAcr.sh
process_image "my-new-container" "dev"

###### winPushContAcr.ps1
Process-Image -imageName "my-new-container" -tag "dev"

5. Done! You now have a new container in your stack.

#### Changing container groups triggers
The time for triggering the container groups are defined in side `containers/logicAppRaw.json` and `containers/logicAppEnriched.json` and `containers/logicAppCurated.json`.
If you would like to change it just edit this part

    "triggers": {
    "trigger_enriched_containergroup": {
        "type": "Recurrence",
        "recurrence": {
        "frequency": "Day",
        "interval": 1,
        "startTime": "2023-09-05T01:01:00Z",
        "timeZone": "UTC"
        }
    }
    }

## Known bugs
#### Unable to locate Storage Account
This one is an issue with Microsoft API response. Await a minute and re-run the deployment again.

## Troubleshooting
#### Containers not acting as expected
1. Ensure it works locally (use python environment to isolate there is no package issues)
2. Check the logs from Azure Container with below command to understand the issue better.
    
        az container show --name <container-name> --resource-group <resource-group-name>

#### Unable to create Blob access in Notebook
Ensure you are signed in, can be achieved by executing "az login --use-device-code" in seperate terminal.

#### Expired device code
Re-run the deployment script and it will automatically refresh the device code.

<!-- CONTACT -->
## Contact

### Martin Karlsson

LinkedIn : [martin-karlsson][linkedin-url] \
X : [@HelloKarlsson](https://x.com/HelloKarlsson) \
Email : hello@martinkarlsson.io \
Webpage : [www.martinkarlsson.io](https://www.martinkarlsson.io)

<!-- MARKDOWN LINKS & IMAGES -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/martin-karlsson
[arch]: img/architecture.png
[depArch]: img/deploymentArchitecture.png