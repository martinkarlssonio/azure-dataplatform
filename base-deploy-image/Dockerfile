FROM fedora:38
# Install Terraform
RUN dnf install -y dnf-plugins-core
RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
RUN dnf -y install terraform

# Install Azure CLI
RUN dnf -y install azure-cli
RUN dnf -y install jq

# Azure CLI PIP dependencies
RUN dnf install python3-pip -y
RUN pip3 install azure-mgmt-logic