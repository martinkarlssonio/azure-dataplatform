## This script is used to create the final resources that are not possible to create with IaC templates.
## Executed inside the container 'live-deploy' during Container deployment phase.

## Login to Az
az login \
--service-principal \
--tenant ${TF_VAR_arm_tenant_id} \
--username ${TF_VAR_arm_client_id} \
--password ${TF_VAR_arm_client_secret} \
--output table

# az acr login --name "${TF_VAR_acr_name}" --username "${TF_VAR_arm_client_id}" --password "${TF_VAR_arm_client_secret}"

## Some items are not possible to do with IaC templates, hence it can be good to have a final step with CLI commands.
az config set extension.use_dynamic_install=yes_without_prompt
### Creating build folder
rm -rf build
mkdir build
### Create an API connection to the container instances, this is needed for the logic app to be able to start the containers
#Service Principal

az resource create \
  --resource-type "Microsoft.Web/connections" \
  --name "aci" \
  --resource-group "${TF_VAR_env}-dataplatform-container" \
  --location ${TF_VAR_rg_location} \
  --properties "{ \
    \"displayName\": \"aci\", \
    \"parameterValues\": { \
      \"token:clientId\": \"$TF_VAR_arm_client_id\", \
      \"token:clientSecret\": \"$TF_VAR_arm_client_secret\", \
      \"token:TenantId\": \"$TF_VAR_arm_tenant_id\", \
      \"token:grantType\": \"client_credentials\" \
    }, \
    \"api\": { \
      \"id\": \"subscriptions/$TF_VAR_subscription_id/providers/Microsoft.Web/locations/westeurope/managedApis/aci\" \
    } \
  }"

### RAW LOGIC APP
cp logicAppRaw.json build/logicAppRaw.json
cd build
sed -i "s/TF_VAR_subscription_id/$TF_VAR_subscription_id/" logicAppRaw.json
sed -i "s/TF_VAR_rg_name/${TF_VAR_env}-dataplatform-container/" logicAppRaw.json
sed -i "s/TF_VAR_raw_ctgrp_name/$TF_VAR_raw_ctgrp_name/" logicAppRaw.json
sed -i "s/TF_VAR_rg_location/$TF_VAR_rg_location/" logicAppRaw.json
echo "################# Creating Raw Logic App"
az logic workflow create --resource-group ${TF_VAR_env}-dataplatform-container/ --location ${TF_VAR_rg_location} --name "logicAppRaw" --definition "logicAppRaw.json"

### ENRICHED LOGIC APP
cd ..
cp logicAppEnriched.json build/logicAppEnriched.json
cd build
sed -i "s/TF_VAR_subscription_id/$TF_VAR_subscription_id/" logicAppEnriched.json
sed -i "s/TF_VAR_rg_name/${TF_VAR_env}-dataplatform-container/" logicAppEnriched.json
sed -i "s/TF_VAR_enriched_ctgrp_name/$TF_VAR_enriched_ctgrp_name/" logicAppEnriched.json
sed -i "s/TF_VAR_rg_location/$TF_VAR_rg_location/" logicAppEnriched.json
echo "################# Creating Enriched Logic App"
az logic workflow create --resource-group ${TF_VAR_env}-dataplatform-container/ --location ${TF_VAR_rg_location} --name "logicAppEnriched" --definition "logicAppEnriched.json"

### CURATED LOGIC APP
cd ..
cp logicAppCurated.json build/logicAppCurated.json
cd build
sed -i "s/TF_VAR_subscription_id/$TF_VAR_subscription_id/" logicAppCurated.json
sed -i "s/TF_VAR_rg_name/${TF_VAR_env}-dataplatform-container/" logicAppCurated.json
sed -i "s/TF_VAR_curated_ctgrp_name/$TF_VAR_curated_ctgrp_name/" logicAppCurated.json
sed -i "s/TF_VAR_rg_location/$TF_VAR_rg_location/" logicAppCurated.json
echo "################# Creating Logic App"
az logic workflow create --resource-group ${TF_VAR_env}-dataplatform-container/ --location ${TF_VAR_rg_location} --name "logicAppCurated" --definition "logicAppCurated.json"