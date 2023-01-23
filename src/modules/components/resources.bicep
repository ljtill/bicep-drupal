// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Key Vault

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: settings.resources.keyVault.name
  location: settings.resourceGroup.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
    enableSoftDelete: false
  }
  resource databaseUsername 'secrets' = {
    name: 'database-username'
    properties: {
      value: username
    }
  }
  resource databasePassword 'secrets' = {
    name: 'database-password'
    properties: {
      value: password
    }
  }
}

// Storage Account

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: settings.resources.storageAccount.name
  location: settings.resourceGroup.location
  kind: 'FileStorage'
  sku: {
    name: 'Premium_LRS'
  }
  resource fileServices 'fileServices' = {
    name: 'default'
    resource fileShareDrupal 'shares' = {
      name: shareName.drupalData
    }
    resource fileShareMariaDb 'shares' = {
      name: shareName.mariadbCert
    }
  }
}

// MariaDB

resource mariaDb 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: settings.resources.mariaDb.name
  location: settings.resourceGroup.location
  sku: {
    name: 'GP_Gen5_4'
  }
  properties: {
    createMode: 'Default'
    version: '10.3'
    administratorLogin: username
    administratorLoginPassword: password
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
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
  name: settings.resources.appServicePlan.name
  location: settings.resourceGroup.location
  properties: {
    reserved: true
  }
  kind: 'linux'
  sku: {
    name: 'P1V2'
  }
}
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: settings.resources.appService.name
  location: settings.resourceGroup.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${imageName.nginx}'
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
          name: 'DRUPAL_DATABASE_TLS_CA_FILE'
          value: '/usr/local/share/ca-certificates/mariadb/BaltimoreCyberTrustRoot.crt.pem'
        }
        {
          name: 'DRUPAL_DATABASE_USER'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-username)'
        }
        {
          name: 'DRUPAL_DATABASE_PASSWORD'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-password)'
        }
        {
          name: 'MYSQL_CLIENT_ENABLE_SSL'
          value: 'yes'
        }
      ]
    }
  }
  resource configMounts 'config' = {
    name: 'azurestorageaccounts'
    properties: {
      '${shareName.drupalData}': {
        type: 'AzureFiles'
        shareName: shareName.drupalData
        mountPath: '/bitnami/drupal'
        accountName: storageAccount.name
        accessKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
      }
      '${shareName.mariadbCert}': {
        type: 'AzureFiles'
        shareName: shareName.mariadbCert
        mountPath: '/usr/local/share/ca-certificates/mariadb'
        accountName: storageAccount.name
        accessKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
      }
    }
  }
}

// Deployment Script

resource script 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: settings.resources.deploymentScript.name
  location: settings.resourceGroup.location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.41.0'
    retentionInterval: 'PT1H'
    cleanupPreference: 'Always'
    scriptContent: loadTextContent('../../scripts/deploy.sh')
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_NAME'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        value: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
      }
      {
        name: 'SHARE_NAME'
        value: shareName.mariadbCert
      }
    ]
  }
}

// Role Assignment

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('roleAssignment', keyVault.id, appService.id)
  scope: keyVault
  properties: {
    principalType: 'ServicePrincipal'
    principalId: appService.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
  }
}

// ---------
// Variables
// ---------

var databaseName = 'bitnami_drupal'
var imageName = {
  apache: 'bitnami/drupal:latest'
  nginx: 'bitnami/drupal-nginx:latest'
}
var shareName = {
  drupalData: 'drupal-data'
  mariadbCert: 'mariadb-cert'
}

// ----------
// Parameters
// ----------

param defaults object
param settings object

@secure()
param username string
@secure()
param password string
