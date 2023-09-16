outputJson=$(terraform output -json | jq .)
rm -rf coreOutput.json
echo ${outputJson} >> coreOutput.json
cp coreOutput.json /output/coreOutput.json

#Export ResourceGroup details
TF_VAR_rg_name=$(echo ${outputJson} | jq .rg_name.value)
export TF_VAR_rg_name=$(echo ${TF_VAR_rg_name//'"'})
#echo "RG NAME : ${TF_VAR_rg_name}"
echo "TF_VAR_rg_name=${TF_VAR_rg_name}" >> /output/.envTf

TF_VAR_rg_location=$(echo ${outputJson} | jq .rg_location.value)
export TF_VAR_rg_location=$(echo ${TF_VAR_rg_location//'"'})
#echo "RG LCOATION : ${TF_VAR_rg_location}"
echo "TF_VAR_rg_location=${TF_VAR_rg_location}" >> /output/.envTf

#Export StorageAccount details
TF_VAR_stacc_name=$(echo ${outputJson} | jq .stacc_name.value)
export TF_VAR_stacc_name=$(echo ${TF_VAR_stacc_name//'"'})
#echo "STACC NAME : ${TF_VAR_stacc_name}"
echo "TF_VAR_stacc_name=${TF_VAR_stacc_name}" >> /output/.envTf

#Export ContainerRegistry details
TF_VAR_acr_name=$(echo ${outputJson} | jq .acr_name.value)
export TF_VAR_acr_name=$(echo ${TF_VAR_acr_name//'"'})
#echo "ACR NAME : ${TF_VAR_acr_name}"
echo "TF_VAR_acr_name=${TF_VAR_acr_name}" >> /output/.envTf