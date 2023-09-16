terraform init -upgrade
terraform plan -out main.tfplan
terraform apply main.tfplan
#Export output, running as source ensure it gets exported properly
echo "core/deploy.sh : Current directory: "
pwd
source exportTfOutput.sh
