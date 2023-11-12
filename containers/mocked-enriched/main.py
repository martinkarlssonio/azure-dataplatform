"""
This code is responsible for enriching the raw data with the time it took to close the tickets.
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
    ## Fetch the core details (e.g. storage account name)
    with open("coreOutput.json") as file:
        # Load its content and make a new dictionary
        coreOutput = json.load(file)
    stacc_name = coreOutput["stacc_name"]["value"]
    print("stacc_name: {}".format(stacc_name))
    ## Read file stacc_key and load all the text into a variable
    with open("stacc_key", "r") as file:
        stacc_key = file.read()

except Exception as e:
    print("Error: {}".format(e))
    logging.error("Error: {}".format(e))

# Get access to blob storage
try:
    from azure.storage.blob import BlobServiceClient
    account_url = "https://"+stacc_name+".blob.core.windows.net"
    blob_service_client = BlobServiceClient(account_url, credential={"account_name": stacc_name, "account_key":stacc_key})
    container_name = "mocked-raw"
except Exception as e:
    print("Error connecting to Blob : {}".format(e))
    logging.error("Error connecting to Blob : {}".format(e))


def loadDataFromBlob():
    container_name = "mocked-raw"
    from azure.identity import DefaultAzureCredential
    credential = DefaultAzureCredential()

    from azure.storage.blob import BlobServiceClient#, BlobClient, ContainerClient
    """ 
    Connect to Blob Storage
    """
    account_url = "https://"+stacc_name+".blob.core.windows.net"
    # Create the BlobServiceClient object
    blob_service_client = BlobServiceClient(account_url, credential=credential)
    # Create a unique name for the blob container
    container_name = "mocked-raw"

    try:
        container_client = blob_service_client.get_container_client(container_name)
        print("mocked-enriched ::: Loading data from blob storage")
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

        dfRaw = pl.read_parquet(
            source=local_directory,
            use_pyarrow=True
            )

        print("dfRaw read from blob storage")
        return dfRaw

    except Exception as e:
        print("Error: {}".format(e))
        logging.error("Error: {}".format(e))
        return

def uploadParquets(directory_path):
    print("mocked-enriched ::: Uploading parquet files to blob storage")
    # Create a unique name for the blob container
    container_name = "mocked-enriched"

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

def enrichDf(dfRaw):
    print("mocked-enriched ::: Enriching data")
    #dfEnriched = dfRaw
    dffInNs = (dfRaw["Closed_Timestamp"] - dfRaw["Open_Timestamp"]).cast(pl.Int64)
    dfEnriched = dfRaw.with_columns((dffInNs / (60 * 1_000_000)).alias("Minutes_To_Close"))
    pl.Config.set_tbl_cols(15) #Config for amount of columns to display
    print(dfEnriched.head())
    return dfEnriched

if __name__ == '__main__':
    try:
        print("###################### ENRICHED CONTAINER STARTING")
        logging.info("###################### ENRICHED CONTAINER STARTING")
        time.sleep(5)
        print("{} Hello from mocked-enriched".format(currentTime))
        dfRaw = loadDataFromBlob()
        dfEnriched = enrichDf(dfRaw)
        dirPath = "data/toBlobStorage"
        storeDf(dfEnriched,dirPath)
        uploadParquets(dirPath)
        print("mocked-enriched ::: Main done. Closing down! Good bye.")
    except Exception as e:
        print("Error: {}".format(e))
        logging.error("Error: {}".format(e))