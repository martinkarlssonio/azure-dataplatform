## Login to Az
az login \
--service-principal \
--tenant ${TF_VAR_arm_tenant_id} \
--username ${TF_VAR_arm_client_id} \
--password ${TF_VAR_arm_client_secret} \
--output table

az group delete --resource-group ${TF_VAR_env}-dataplatform-container --yes
