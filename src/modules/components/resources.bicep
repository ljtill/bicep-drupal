// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// -----
// Notes
// -----

// ---------
// Resources
// ---------

// Key Vault

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: config.resources.name
  location: config.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableSoftDelete: false
  }
  resource accessPolicies 'accessPolicies' = {
    name: 'add'
    properties: {
      accessPolicies: [
        {
          tenantId: tenant().tenantId
          objectId: appService.identity.principalId
          permissions: {
            secrets: [
              'get'
            ]
          }
        }
      ]
    }
  }
  resource databaseUsername 'secrets' = {
    name: 'database-username'
    properties: {
      value: credential.username
    }
  }
  resource databasePassword 'secrets' = {
    name: 'database-password'
    properties: {
      value: credential.password
    }
  }
}

// Storage Account

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: config.resources.name
  location: config.location
  kind: 'FileStorage'
  sku: {
    name: 'Premium_LRS'
  }
  resource fileServices 'fileServices' = {
    name: 'default'
    resource fileShare 'shares' = {
      name: shareName
    }
  }
}

// MariaDB

resource mariaDb 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: config.resources.name
  location: config.location
  properties: {
    administratorLogin: credential.username
    administratorLoginPassword: credential.password
    createMode: 'Default'
    publicNetworkAccess: 'Enabled'
    sslEnforcement: 'Disabled'
    version: '10.3'
  }
  resource database 'databases' = {
    name: databaseName
  }
  resource firewall 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

// App Service

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: config.resources.name
  location: config.location
  properties: {
    reserved: true
  }
  kind: 'linux'
  sku: {
    name: 'P1v3'
  }
}
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: config.resources.name
  location: config.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|bitnami/drupal:latest'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '1800'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DRUPAL_DATABASE_HOST'
          value: '${mariaDb.name}.mariadb.database.azure.com'
        }
        {
          name: 'DRUPAL_DATABASE_PORT_NUMBER'
          value: '3306'
        }
        {
          name: 'DRUPAL_DATABASE_NAME'
          value: databaseName
        }
        {
          name: 'DRUPAL_DATABASE_USER'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-username)'
        }
        {
          name: 'DRUPAL_DATABASE_PASSWORD'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-password)'
        }
      ]
    }
  }
  resource fileShareMount 'config' = {
    name: 'azurestorageaccounts'
    properties: {
      '${shareName}': {
        type: 'AzureFiles'
        shareName: shareName
        mountPath: '/bitnami/drupal'
        accountName: storageAccount.name
        accessKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
      }
    }
  }
}

// ---------
// Variables
// ---------

var shareName = 'drupal-data'
var databaseName = 'bitnami_drupal'

// ----------
// Parameters
// ----------

param config object

@secure()
param credential object
