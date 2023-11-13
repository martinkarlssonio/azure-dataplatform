"""
The main script that controls the deployment towards Azure.
It is executed inside the container 'live-deploy'
"""
import os
import time
import json


####################################################################
########################## FUNCTIONS ###############################
####################################################################


def getEnvDataAsDict(path: str) -> dict:
    with open(path, 'r') as f:
       return dict(tuple(line.replace('\n', '').split('=')) for line
                in f.readlines() if not line.startswith('#'))

def setCred():
    os.system("bash /setCred.sh")
    ## Give Azure some time to propagate the credentials
    time.sleep(10)

def loadEnvVar():
    print("Loading environment variables...")
    try:
        """
        Fetch the env variables and ensure they are set in the os.environ
        """
        envVariables = getEnvDataAsDict('/output/.envTf')
        for variable in envVariables.keys():
            os.environ[variable] = envVariables[variable]
            try:
                if os.environ[variable]:
                    pass
                else:
                    return False
            except Exception as e:
                print(e)
                return False
        return True
    except Exception as e:
        print(e)
        return False
    
def coreExist():
    print("Core already deployed, finding details.")
    resourceList = os.popen("az resource list --resource-group {}".format(rgName)).read()
    resourceList = json.loads(resourceList)
    acrName = ""
    rgLocation = ""
    staccName = ""
    for resource in list(resourceList):
        resourceName = resource['name']
        resourceId = resource['id']
        resourceType = resource['type']
        if "storageaccount" in resourceType.lower():
            staccName = resourceName
        if "containerregistry" in resourceType.lower():
            acrName = resourceName
            rgLocation = resource['location']
    coreOutput = {
                    "acr_name": {
                        "value": acrName
                    },
                    "rg_location": {
                        "value": rgLocation
                    },
                    "rg_name": {
                        "value": rgName
                    },
                    "stacc_name": {
                        "value": staccName
                    }
                }
    # Writing the details to file
    with open("coreOutput.json", "w") as fp:
        json.dump(coreOutput, fp)
    # Copy the file to the output folder (this folder is accessable by the host when the container is started with -v "output:/output")
    os.system("cp coreOutput.json /output/coreOutput.json")
    os.system("cp coreOutput.json /containers/coreOutput.json &&\
            cp coreOutput.json /output/coreOutput.json\
                ")
    # Export environment variables
    os.environ["TF_VAR_acr_name"] = acrName
    os.environ["TF_VAR_rg_location"] = rgLocation
    os.environ["TF_VAR_rg_name"] = rgName
    os.environ["TF_VAR_stacc_name"] = staccName
    os.system('echo "TF_VAR_acr_name=${TF_VAR_acr_name}" >> /output/.envTf')
    os.system('echo "TF_VAR_stacc_name=${TF_VAR_stacc_name}" >> /output/.envTf')
    os.system('echo "TF_VAR_rg_location=${TF_VAR_rg_location}" >> /output/.envTf')
    os.system('echo "TF_VAR_rg_name=${TF_VAR_rg_name}" >> /output/.envTf')
    os.system('cd core && bash exportStaccKey.sh')
    os.system('cd core && bash exportAcrKey.sh')
    print("Starting exportManId")
    os.system('cd core && bash exportManId.sh')
    print("DONE exportManId")
    return

def coreNotExist():
    print("Core not yet deployed, deploying it!")
    # Setting Terraform Trace Logs
    # os.environ["TF_LOG"] = "TRACE"
    # os.system('export TF_LOG="TRACE"')
    loadEnvVar()
    os.system("cd core && \
            echo '#################################### Terraform Init' && \
            terraform init -upgrade && \
            echo '#################################### Terraform Plan' && \
            terraform plan -out main.tfplan && \
            echo '#################################### Terraform Apply' && \
            terraform apply main.tfplan && \
            echo 'Exporting output from Core Terraform...' && \
            bash exportTfOutput.sh && \
            bash exportStaccKey.sh && \
            bash exportAcrKey.sh && \
            bash exportManId.sh && \
            cp coreOutput.json ../containers/coreOutput.json &&\
            cp coreOutput.json /output/coreOutput.json\
                ")
    return True

def deployContainers():
    # Add Azure credentials to the deployment container
    os.system("cp -r /output/.azure ~/.azure")
    os.system("cp -r /output/.azure /root/.azure")
    # Triggered if the environmental variable is set to containers
    print("Deploying Containers...")
    # Setting Terraform Trace Logs
    # os.environ["TF_LOG"] = "TRACE"
    # os.system('export TF_LOG="TRACE"')
    # Containers should already be pushed to ACR prior to this step
    if loadEnvVar():
        os.system("cd containers && bash setAcrAccess.sh")
        # with open("/output/man_id", "r") as file:
        #     man_id = file.read()
        #     man_id = man_id.replace("\n", "")
        #     man_id = man_id.replace("resourcegroups", "resourceGroups")
        # with open("/output/man_prin_id", "r") as file:
        #     man_prin_id = file.read()
        #     man_prin_id = man_prin_id.replace("\n", "")
        #     man_prin_id = man_prin_id.replace("resourcegroups", "resourceGroups")
        # os.environ["TF_VAR_man_id"] = man_id
        # os.environ["TF_VAR_man_prin_id"] = man_prin_id
        loadEnvVar()
        # os.system("cd containers && \
        #         bash final.sh \
        #         ")
        os.system("cd containers && \
                bash deleteOldDeploy.sh && \
                bash setAcrAccess.sh && \
                terraform init -upgrade && \
                terraform plan -out main.tfplan && \
                terraform apply main.tfplan && \
                source ./exportTfOutput.sh && \
                sleep 10 && \
                bash final.sh \
                ")
    else:
        print("Could not load environment variables")
        return False
    return True


####################################################################
########################## MAIN ####################################
####################################################################

if __name__ == '__main__':
    try:
        if os.environ["PHASE"] == "core":
            # Triggered if the environmental variable is set to core
            # Setting credentials, it will ask to manually login to Azure
            setCred()
            # Loading environment variables
            if loadEnvVar():
                rgName = "{}-dataplatform-core".format(os.environ["TF_VAR_env"])
                groupShow = os.popen("az group show --resource-group {}".format(rgName)).read()
                if "succeeded" in groupShow.lower():
                    # Core already deployed, but need to fetch all the resource details for Container deployments
                    coreExist()
                else:
                    # Core is not yet deployed, proceeding with deployment of it.
                    coreNotExist()
        elif os.environ["PHASE"] == "containers":
            deployContainers()
        else:
            print("Missing phase variable")
    except Exception as e:
        print(e)