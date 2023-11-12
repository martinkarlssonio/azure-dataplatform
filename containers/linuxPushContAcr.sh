## This script will push the images to the Azure Container Registry
# Load variables from .envTf
cp ../output/.envTf .envTf
#cp ../output/.envBlob .env
pwd=$(pwd)
source ${pwd}/.envTf

# ## Login to Az
# az login \
# --service-principal \
# --tenant ${TF_VAR_arm_tenant_id} \
# --username ${TF_VAR_arm_client_id} \
# --password ${TF_VAR_arm_client_secret} \
# --output table

# ## Login to ACR
# az acr login --name "${TF_VAR_acr_name}" --username "${TF_VAR_arm_client_id}" --password "${TF_VAR_arm_client_secret}"

## Login to ACR using credentials from 'az login'
az acr login --name "${TF_VAR_acr_name}" 

# Fetch all Container Repositories in ACR
repositories=$(az acr repository list --name $TF_VAR_acr_name | jq -r '.[]')

# Initialize an empty array to store existing images
images=()
for repository in $repositories; do
    # List all the tags for each repository
    tags=$(az acr repository show-tags --name $TF_VAR_acr_name --repository $repository | jq -r '.[]')
    
    for tag in $tags; do
        image="${repository}:${tag}"
        images+=("$image")
    done
done

## Function that will push new images to Container Registry
function process_image() {
    local imageName=$1
    local tag=$2
    local combinedName="${imageName}:${tag}"

    if [[ " ${images[@]} " =~ " ${combinedName} " ]]; then
        echo "$combinedName already exists in container registry"
    else
        cp -r ../output/.azure ${imageName}/.azure
        echo "Pushing $combinedName to container registry"
        #cp .env "${imageName}/.env"
        cp ../output/coreOutput.json "${imageName}/coreOutput.json"
        sleep 5
        cd "${imageName}"
        docker build -t "${combinedName}" .
        sleep 5
        docker images
        docker tag "${combinedName}" "$TF_VAR_acr_name.azurecr.io/${combinedName}"
        docker push "$TF_VAR_acr_name.azurecr.io/${combinedName}"
        cd ..
    fi
}

###################### IMAGES TO PROCESS
## If you want to release a new version of an image, do not forget to change the tag both here and in terraform.
process_image "mocked-raw" "dev"
# process_image "mocked-enriched" "dev"
# process_image "mocked-curated" "dev"
process_image "container-scheduler" "dev"