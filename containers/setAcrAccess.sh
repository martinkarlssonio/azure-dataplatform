echo "Signing in to Azure Container Registry"
acrLogin=$(az acr login --name ${TF_VAR_acr_name} --expose-token)
echo ${acrLogin} | jq .
#Fetch Access Token and LoginServer
accessToken=$(echo ${acrLogin} | jq .accessToken)
export TF_VAR_acr_access_token=$(echo ${accessToken//'"'})
echo ${TF_VAR_acr_access_token}
echo "TF_VAR_acr_access_token=${TF_VAR_acr_access_token}" >> /output/.envTf

## Accesstoken expires after 90min by default, uses username and password for container instances
acr_username=$(cat /output/acr_username)
export TF_VAR_acr_username=$(echo ${acr_username//'"'})
echo ${TF_VAR_acr_password}
echo "TF_VAR_acr_password=${TF_VAR_acr_password}" >> /output/.envTf

acr_password=$(cat /output/acr_password)
export TF_VAR_acr_password=$(echo ${acr_password//'"'})
echo ${TF_VAR_acr_password}
echo "TF_VAR_acr_password=${TF_VAR_acr_password}" >> /output/.envTf

# echo ${TF_VAR_acr_access_token} >> /output/acr_access_token