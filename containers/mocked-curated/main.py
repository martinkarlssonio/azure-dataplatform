"""
This code is responsible for curating the enriched data. 
It removes all rows where the category column has the value 'Hardware'.
"""

import time
import logging
from datetime import datetime
import json

now = datetime.now()
currentTime = now.strftime("%H:%M:%S")
import polars as pl
import os
from pathlib import Path


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

def loadDataFromBlob():
    container_name = "mocked-enriched"
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
    container_name = "mocked-enriched"

    try:
        container_client = blob_service_client.get_container_client(container_name)
        print("mocked-CURATED ::: Loading data from blob storage")
        blob_list = container_client.list_blobs()
        local_directory = "data/fromBlobStorage"
        os.makedirs(local_directory, exist_ok=True)

        # List the blobs in the container
        blob_list = container_client.list_blobs()
        for blob in blob_list:
            # Check if the blob is a .parquet file
            if blob.name.endswith('.parquet'):
                #print(f"Downloading {blob.name} to local storage...")
                blob_client = container_client.get_blob_client(blob=blob.name)
                
                local_file_path = os.path.join(local_directory, blob.name)

                # Ensure directories exist
                Path(os.path.dirname(local_file_path)).mkdir(parents=True, exist_ok=True)

                with open(local_file_path, "wb") as f:
                    data = blob_client.download_blob()
                    data.readinto(f)

        dfEnriched = pl.read_parquet(
            source=local_directory,
            use_pyarrow=True
            )

        print("dfEnriched read from blob storage")
        return dfEnriched

    except Exception as e:
        print("Error: {}".format(e))
        logging.error("Error: {}".format(e))
        return

def uploadParquets(dirPath):
    print("mocked-CURATED ::: Uploading parquet files to blob storage")
    # #Loading DefaultAzureCredential, will by default load env. variables named: AZURE_TENANT_ID/AZURE_CLIENT_ID/AZURE_USERNAME/AZURE_TENANT_ID
    # from azure.identity import DefaultAzureCredential
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
    container_name = "mocked-curated"

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
    for dirpath, dirnames, filenames in os.walk(dirPath):
        for filename in filenames:
            if ".parquet" in filename and ".crc" not in filename: # Only upload parquet files
                # Construct the full local path
                file_path = os.path.join(dirpath, filename)
                
                # Construct blob name with folder structure
                # This will preserve the directory structure in blob storage
                blob_name = os.path.relpath(file_path, dirPath)
                
                # Upload each file
                blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
                #print(f"Uploading {file_path} to blob as {blob_name}")
                
                try:
                    with open(file_path, "rb") as data:
                        blob_client.upload_blob(data)
                except Exception as e:
                    print(f"Failed to upload {file_path}. Error: {e}")
def storeDf(df,dirPath):
    df.write_parquet(
        dirPath,
        use_pyarrow=True,
        pyarrow_options={"partition_cols": ["Open_Year", "Open_Month", "Open_Day"]},
    )

def curateDf(dfEnriched):
    print("mocked-CURATED ::: Curating the data")
    # Remove rows where category column has the value 'Hardware'
    dfCurated = dfEnriched.filter(dfEnriched['category'] != 'Hardware')
    pl.Config.set_tbl_cols(15) #Config for amount of columns to display
    print(dfCurated.head())
    return dfCurated

if __name__ == '__main__':
    try:
        print("###################### CURATED CONTAINER STARTING")
        logging.info("###################### CURATED CONTAINER STARTING")
        time.sleep(5)
        print("{} Hello from mocked-CURATED".format(currentTime))
        dfEnriched = loadDataFromBlob()
        dfCurated = curateDf(dfEnriched)
        dirPath = "data/toBlobStorage"
        storeDf(dfCurated,dirPath)
        uploadParquets(dirPath)
        print("mocked-CURATED ::: Main done. Closing down! Good bye.")
    except Exception as e:
        print("Error: {}".format(e))
        logging.error("Error: {}".format(e))