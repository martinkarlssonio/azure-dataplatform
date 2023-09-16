
# #Deploy core infrastructure
echo "scripts/deploy.sh : Current directory: "
pwd
cd ../core && pwd && terraform init -upgrade && terraform plan -out main.tfplan && terraform apply main.tfplan && source ./exportTfOutput.sh
echo "scripts/deploy.sh : Current directory: "
pwd
# #Deploy containers
# #Ensure Docker is running
# docker exec -u root -t -i container_id /bin/bash
cd ../containers && pwd && terraform init -upgrade && terraform plan -out main.tfplan && terraform apply main.tfplan && bash buildDeployFunctions.sh