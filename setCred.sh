## This script will create the needed credentials for the deployment
## It is executed inside the container 'live-deploy'
#Sign in to Azure
echo "########################### Apologize, but we need you to sign in for us again. :-)"
subDetails=$(az login --use-device-code)
#echo ${subDetails} | jq .
# #Fetch Subscription ID (Using the first)
# subDetails=$(echo ${subDetails} | jq .[0])
# SUBSCRIPTION_ID=$(echo ${subDetails} | jq .id)

echo "setCred - Testing so we have Azure CLI access"
az ad signed-in-user show
echo "Setting Subscription"
SUBSCRIPTION_ID=$(az account list --all --query '[0].id' -o tsv)
export SUBSCRIPTION_ID=$(echo ${SUBSCRIPTION_ID//'"'})
export TF_VAR_subscription_id=$(echo ${SUBSCRIPTION_ID})
echo ${TF_VAR_subscription_id}
az account set --subscription ${SUBSCRIPTION_ID}

# #CREATE NEEDED ROLES TO THIS SUBSCRIPTION
# echo "Creating Roles"
# #rbacCred=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
# rbacCredDeploy=$(az ad sp create-for-rbac --role="Owner" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
# echo ${rbacCredDeploy}
# rbacCredContainer=$(az ad sp create-for-rbac --role="Storage Blob Data Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
# echo ${rbacCredContainer}

# ####### EXPORTING ALL THE CREDENTIALS
# echo "Exporting Credentials"
# #Deployment Role
# ARM_CLIENT_ID=$(echo ${rbacCredDeploy} | jq .appId)
# export ARM_CLIENT_ID=$(echo ${ARM_CLIENT_ID//'"'})
# export TF_VAR_arm_client_id=$(echo ${ARM_CLIENT_ID})
# echo ${TF_VAR_arm_client_id}

# ARM_CLIENT_SECRET=$(echo ${rbacCredDeploy} | jq .password)
# export ARM_CLIENT_SECRET=$(echo ${ARM_CLIENT_SECRET//'"'})
# export TF_VAR_arm_client_secret=$(echo ${ARM_CLIENT_SECRET})
# echo ${TF_VAR_arm_client_secret}

# ARM_TENANT_ID=$(echo ${rbacCredDeploy} | jq .tenant)
# export ARM_TENANT_ID=$(echo ${ARM_TENANT_ID//'"'})
# export TF_VAR_arm_tenant_id=$(echo ${ARM_TENANT_ID})
# echo ${TF_VAR_arm_tenant_id}

#Write to .envTf file
echo "Writing to .envTf file"
rm -rf .envTf
# echo "TF_VAR_arm_client_id=${TF_VAR_arm_client_id}" >> .envTf
# echo "TF_VAR_arm_client_secret=${TF_VAR_arm_client_secret}" >> .envTf
# echo "TF_VAR_arm_tenant_id=${TF_VAR_arm_tenant_id}" >> .envTf
echo "TF_VAR_subscription_id=${TF_VAR_subscription_id}" >> .envTf
cp .envTf /output/.envTf

# #Container & Notebook Role
# CONT_CLIENT_ID=$(echo ${rbacCredContainer} | jq .appId)
# CONT_CLIENT_ID=$(echo ${CONT_CLIENT_ID//'"'})
# # export TF_VAR_arm_client_id=$(echo ${ARM_CLIENT_ID})
# # echo ${TF_VAR_arm_client_id}

# CONT_CLIENT_SECRET=$(echo ${rbacCredContainer} | jq .password)
# CONT_CLIENT_SECRET=$(echo ${CONT_CLIENT_SECRET//'"'})
# # export TF_VAR_arm_client_secret=$(echo ${ARM_CLIENT_SECRET})
# # echo ${TF_VAR_arm_client_secret}

# CONT_TENANT_ID=$(echo ${rbacCredContainer} | jq .tenant)
# CONT_TENANT_ID=$(echo ${CONT_TENANT_ID//'"'})
# # export TF_VAR_arm_tenant_id=$(echo ${ARM_TENANT_ID})
# # echo ${TF_VAR_arm_tenant_id}

# #Write to .envBlob file
# echo "Writing to .envBlob file"
# rm -rf .envBlob
# echo "BLOB_client_id=${CONT_CLIENT_ID}" >> .envBlob
# echo "BLOB_client_secret=${CONT_CLIENT_SECRET}" >> .envBlob
# echo "BLOB_tenant_id=${CONT_TENANT_ID}" >> .envBlob
# cp .envBlob containers/.env
# cp .envBlob notebooks/.env
# cp .envBlob /output/.envBlob

#Export azure credentials
cp -r ~/.azure /output/

#Change permissions
chmod -R 777 /output