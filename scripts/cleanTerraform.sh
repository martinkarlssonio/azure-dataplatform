## This script will remove all terraform files from the core and containers directories
cd ../core && \
rm -rf terraform.tfstate* && \
rm -rf .terraform && \
rm -rf main.tfplan && \
rm -rf .terraform.lock.hcl && \
cd ../containers && \
rm -rf terraform.tfstate* && \
rm -rf .terraform && \
rm -rf main.tfplan && \
rm -rf .terraform.lock.hcl 