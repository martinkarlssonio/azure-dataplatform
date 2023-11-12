#!/bin/bash
# Command to get credentials
output=$(az acr credential show -n devdpvulrf19)

# Parse the JSON output to extract the username and first password
username=$(echo "$output" | jq -r '.username')
first_password=$(echo "$output" | jq -r '.passwords[0].value')