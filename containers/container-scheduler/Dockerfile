FROM fedora:38
ADD .azure /
ADD .azure ~/.azure
ADD .azure /root/.azure
RUN dnf install -y dnf-plugins-core
# Install Azure CLI
RUN dnf -y install azure-cli
RUN dnf -y install jq
CMD ["bash", "main.sh"]