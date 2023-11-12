#Export STACC Access Key
staccKeyList=$(az storage account keys list -g ${TF_VAR_rg_name} -n ${TF_VAR_stacc_name})
#Extract the first key's value
staccKey=$(echo $staccKeyList | jq -r '.[0].value')
export stacc_key=$(echo ${staccKey//'"'})
echo ${stacc_key} >> /output/stacc_key