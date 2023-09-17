## This script is used to run the deployment process on a Linux machine.
## It will build the base image, deploy the core resources, build the containers and push them to ACR, and finally deploy the containers.

echo "######################################## EXECUTION STARTING ########################################"
export env="dev"
rm -rf output
echo "################# Building base image"
cd base-deploy-image && docker build . -t deploy-image && cd ..
#docker build . -t deploy-image
## Create new live-deploy image (removing old one if any)
echo "################# Removing old deployment-container and live-deploy image"
docker rm -f $(docker ps -a | grep 'deploy-container') || echo "deploy-container deleted"
sleep 10
docker rmi -f $(docker images | grep 'live-deploy') || echo "live-deploy image deleted"
sleep 10
echo "################# Building deployment image"
docker build . -t live-deploy
sleep 10
#Deploy Core
echo "################# Deploying core"
docker run --name deploy-container -v $(pwd)/output:/output -e "PHASE=core" -e "TF_VAR_env=$env" live-deploy
sleep 30
docker logs -t deploy-container
echo "################# Removing deploy-container"
docker rm -f $(docker ps -a | grep 'deploy-container') || echo "deploy-container deleted"
#Build & Push containers to ACR
sleep 30
echo "################# Building and pushing containers to ACR"
cd containers && sh ./linuxPushContAcr.sh
#Deploy Containers
echo "################# Deploying containers"
cd ..
docker run --name deploy-container -v $(pwd)/output:/output -e "PHASE=containers" -e "TF_VAR_env=$env" live-deploy
echo "################# Removing deploy-container"
docker rm -f $(docker ps -a | grep 'deploy-container') || echo "deploy-container deleted"

echo "################# DEPLOYMENT COMPLETED #################"