#!/bin/bash
# Command to get credentials
output=$(az acr credential show -n ${TF_VAR_acr_name})

# Parse the JSON output to extract the username and first password
acr_username=$(echo "$output" | jq -r '.username')
acr_password=$(echo "$output" | jq -r '.passwords[0].value')

# Export
export acr_username=$(echo ${acr_username//'"'})
echo ${acr_username} >> /output/acr_username
export acr_password=$(echo ${acr_password//'"'})
echo ${acr_password} >> /output/acr_password