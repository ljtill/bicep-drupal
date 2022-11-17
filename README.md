# Drupal

Getting Started

```shell
az deployment sub create \
    --name 'Microsoft.Bicep' \
    --location 'eastus' \
    --template-file './src/main.bicep' \
    --parameters '@./src/params/main.json'
```

Resources

- Resource Group
- Key Vault
- Storage Account
- Web App for Containers
- MariaDB
