"""
This code will generated mocked data and store it under Raw Blob Storage Container as partitioned parquet files.
"""
import time
import logging
from datetime import datetime, timedelta
import os, uuid
import random
import json
import polars as pl

now = datetime.now()
currentTime = now.strftime("%H:%M:%S")

## Load Env variables
import setEnv
setEnv.loadEnvVar()

try:
    client_id=os.environ["BLOB_client_id"]
    client_secret=os.environ["BLOB_client_secret"]
    tenant_id=os.environ["BLOB_tenant_id"]

    ## Fetch the core details (e.g. storage account name)
    with open("coreOutput.json") as file:
        # Load its content and make a new dictionary
        coreOutput = json.load(file)
    stacc_name = coreOutput["stacc_name"]["value"]
    print("stacc_name: {}".format(stacc_name))

except Exception as e:
    print("Error: {}".format(e))
    logging.error("Error: {}".format(e))


# Create a function to upload files in a directory
def uploadParquets(directory_path):
    print("mocked-raw ::: Uploading parquet files to blob storage")
    from azure.identity import ClientSecretCredential 

    credential = ClientSecretCredential(
        tenant_id=tenant_id,
        client_id=client_id,
        client_secret=client_secret,
    )

    from azure.storage.blob import BlobServiceClient#, BlobClient, ContainerClient
    
    """ 
    Connect to Blob Storage
    """
    account_url = "https://"+stacc_name+".blob.core.windows.net"
    # Create the BlobServiceClient object
    blob_service_client = BlobServiceClient(account_url, credential=credential)
    # Create a unique name for the blob container
    container_name = "mocked-raw"

    # Create the container if it doesn't exist, or get its client if it does
    try:
        container_client = blob_service_client.create_container(container_name)
    except Exception as e:
        if "ContainerBeingDeleted" in str(e):
            print("Container is currently being deleted. Wait and retry.")
        elif "ContainerAlreadyExists" in str(e):
            print("Container already exists. Getting its client.")
            container_client = blob_service_client.get_container_client(container_name)
        else:
            print(e)

    # Walk through directory
    for dirpath, dirnames, filenames in os.walk(directory_path):
        for filename in filenames:
            if ".parquet" in filename and ".crc" not in filename: # Only upload parquet files
                # Construct the full local path
                file_path = os.path.join(dirpath, filename)
                
                # Construct blob name with folder structure
                # This will preserve the directory structure in blob storage
                blob_name = os.path.relpath(file_path, directory_path)
                
                # Upload each file
                blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
                #print(f"Uploading {file_path} to blob as {blob_name}")
                
                try:
                    with open(file_path, "rb") as data:
                        blob_client.upload_blob(data)
                except Exception as e:
                    print(f"Failed to upload {file_path}. Error: {e}")

def generateMockedData(output_directory):
    """
    Generate mocked data with some data skew
    """
    print("mocked-raw ::: Generating mocked data with Polars")
    # Number of rows
    dataframeN = 100_000

    # Create random data, adding duplicates to have some skew
    priorities = ["Critical", "High", "Medium", "Medium", "Low"]
    categories = ["Software", "Hardware", "Network", "Network", "Security", "Access"]
    assignees = ["User1", "User2", "User2", "User3", "User4", "User5"]
    reporters = ["Reporter1", "Reporter2", "Reporter3", "Reporter4", "Reporter5", "Reporter5"]
    statuses = ["Rejected", "WorkedAround", "Resolved", "Resolved", "Resolved", "Resolved", "Closed"]
    #descriptions = ["Issue with app", "Cannot connect to network", "Permission issue", "Hardware malfunction", "App crash"]

    #Generate mocked data
    priorityList = []
    categoryList = []
    assigneeList = []
    reporterList = []
    statusList = []
    descriptionList = []
    Open_TimestampList = []
    Closed_TimestampList = []
    Open_YearList = []
    Open_MonthList = []
    Open_DayList = []

    
    # Utility functions to generate random data
    def random_date():
        # Get today's date
        today = datetime.today()
        # Subtract random number of days up to a year
        offset = timedelta(days=random.randint(0, 365))
        return today - offset
    
    for n in range(0,dataframeN):
        category = random.choice(categories)
        priorityList.append(random.choice(priorities))
        categoryList.append(category)
        assigneeList.append(random.choice(assignees))
        reporterList.append(random.choice(reporters))
        statusList.append(random.choice(statuses))
        descriptionList.append("I have issues with "+str(category))
        randDate = random_date()
        Open_TimestampList.append(randDate)
        Closed_TimestampList.append(randDate + timedelta(days=random.randint(1, 10)))
        Open_YearList.append(randDate.year)
        Open_MonthList.append(randDate.month)
        Open_DayList.append(randDate.day)

    dataDict = {"priority":priorityList, "category":categoryList, "assignee":assigneeList, "reporter":reporterList, "status":statusList, "description":descriptionList, "Open_Timestamp":Open_TimestampList, "Closed_Timestamp":Closed_TimestampList, "Open_Year":Open_YearList, "Open_Month":Open_MonthList, "Open_Day":Open_DayList}
    df = pl.DataFrame(dataDict)
    pl.Config.set_tbl_cols(11) #Config for amount of columns to display
    print(df.head()) # Display the head of the dataframe
    # Store the dataframe as parquet files, partitioned by year, month and day
    df.write_parquet(
        output_directory,
        use_pyarrow=True,
        pyarrow_options={"partition_cols": ["Open_Year", "Open_Month", "Open_Day"]},
    )
    time.sleep(5)
    return

if __name__ == '__main__':
    try:
        print("###################### RAW CONTAINER STARTING")
        logging.info("###################### RAW CONTAINER STARTING")
        time.sleep(5)
        print("{} Hello from mocked-raw".format(currentTime))
        directoryPath = "data"
        generateMockedData(directoryPath)
        uploadParquets(directoryPath)
        print("mocked-raw ::: Main done. Closing down! Good bye.")
    except Exception as e:
        print("Error: {}".format(e))
        logging.error("Error: {}".format(e))