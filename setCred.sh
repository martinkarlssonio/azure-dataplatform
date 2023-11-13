#Sign in to Azure
echo "########################### Apologize, but we need you to sign in for us again. :-)"
subDetails=$(az login --use-device-code)

echo "setCred - Testing so we have Azure CLI access"
az ad signed-in-user show
echo "Setting Subscription"
SUBSCRIPTION_ID=$(az account list --all --query '[0].id' -o tsv)
export SUBSCRIPTION_ID=$(echo ${SUBSCRIPTION_ID//'"'})
export TF_VAR_subscription_id=$(echo ${SUBSCRIPTION_ID})
echo ${TF_VAR_subscription_id}
az account set --subscription ${SUBSCRIPTION_ID}

#Write to .envTf file
echo "Writing to .envTf file"
rm -rf .envTf
echo "TF_VAR_subscription_id=${TF_VAR_subscription_id}" >> .envTf
cp .envTf /output/.envTf

#Export azure credentials
cp -r ~/.azure /output/

#Change permissions
chmod -R 777 /output