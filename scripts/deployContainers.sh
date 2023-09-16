
#sudo docker exec -u root -t -i container_id /bin/bash
sudo docker ps -l
# #Deploy core infrastructure
# cd /core
# terraform init -upgrade
# terraform plan -out main.tfplan
# terraform apply main.tfplan
# #Export output, running as source ensure it gets exported properly
# source exportTfOutput.sh

# #Deploy containers
# #Ensure Docker is running
# docker exec -u root -t -i container_id /bin/bash
# cd /containers
# #Push containers to ACR (created in core terraform stack)
# sudo bash pushContainerToAcr.sh
# #Deploy containers terraform stack
# terraform init -upgrade
# terraform plan -out main.tfplan
# terraform apply main.tfplan
# #Build and deploy Azure Functions to functions app created in containers terraform stack
# bash buildDeployFunctions.sh
