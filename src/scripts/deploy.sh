#!/bin/bash

echo -e "\n"

# Download
echo "Downloading the Root Certificate..."
curl \
    --silent "https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem" \
    --output /tmp/BaltimoreCyberTrustRoot.crt.pem

# Upload
echo "Uploading the Root Certificate..."
az storage file upload \
    --account-name $AZURE_STORAGE_NAME \
    --account-key $AZURE_STORAGE_KEY \
    --share-name $SHARE_NAME \
    --source "/tmp/BaltimoreCyberTrustRoot.crt.pem" \
    --no-progress \
    --output none
