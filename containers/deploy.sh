## Ensure that correct containers are pushed to ACR before running this script
terraform init -upgrade
terraform plan -out main.tfplan
terraform apply main.tfplan