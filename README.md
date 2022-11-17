# Drupal

```shell
az deployment sub create \
    --name 'Microsoft.Bicep' \
    --location 'eastus' \
    --template-file './src/main.bicep' \
    --parameters '@./src/params/main.json'
```
