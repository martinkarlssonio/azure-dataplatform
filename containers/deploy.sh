## Ensure that correct containers are pushed to ACR before running this script
terraform init -upgrade #\
# -backend-config="rg_name=${TF_VAR_rg_name}"\
# -backend-config="rg_location=${TF_VAR_rg_location}"
terraform plan -out main.tfplan
terraform apply main.tfplan