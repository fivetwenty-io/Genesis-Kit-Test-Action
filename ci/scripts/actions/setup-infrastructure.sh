#!/bin/bash
set -e

echo "🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️" 
echo "🔍 DEBUG: Setting up infrastructure for $IAAS_PROVIDER"
# Install infrastructure-specific tools
case "$IAAS_PROVIDER" in
  vsphere)
    # VSphere specific setup
    echo "🔍 DEBUG: Setting up VSphere tools..."
    # Configure VSphere credentials
    mkdir -p ~/.vsphere
    echo "$VSPHERE_USERNAME" > ~/.vsphere/username
    echo "$VSPHERE_PASSWORD" > ~/.vsphere/password
    echo "✅ VSphere credentials configured"
    ;;
  aws)
    # AWS specific setup
    echo "🔍 DEBUG: Setting up AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    # Configure AWS credentials
    echo "🔍 DEBUG: Configuring AWS credentials"
    mkdir -p ~/.aws
    cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF
    echo "✅ AWS CLI installed and configured"
    ;;
  gcp)
    # GCP specific setup
    echo "🔍 DEBUG: Setting up GCP CLI..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install google-cloud-cli
    # Configure GCP credentials
    echo "🔍 DEBUG: Configuring GCP service account"
    echo "$GCP_SERVICE_ACCOUNT_KEY" > /tmp/gcp-key.json
    gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
    rm /tmp/gcp-key.json
    echo "✅ GCP CLI installed and configured"
    ;;
esac
echo "✅ Infrastructure setup completed for $IAAS_PROVIDER"
echo "🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️🛠️"