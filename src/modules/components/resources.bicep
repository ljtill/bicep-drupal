// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------

// Storage Account

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: ''
  location: location
  kind: 'FileStorage'
  sku: {
    name: 'Premium_LRS'
  }
}
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: storageAccount
  name: 'default'
}
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  parent: fileServices
  name: 'drupal-data' // TODO: Extract to config file
  properties: {}
}

// MariaDB

// TODO: Allow access to Azure services - Yes
// TODO: Enforce SSL connection - Disabled

resource mariaDb 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: ''
  location: location
  properties: {
    administratorLogin: '' // TODO: Extract to config file
    administratorLoginPassword: '' // TODO: Extract to config file
    createMode: 'Default'
    publicNetworkAccess: 'Enabled'
  }
}
resource firewallRule 'Microsoft.DBforMariaDB/servers/firewallRules@2018-06-01' = {
  parent: mariaDb
  name: 'default'
  properties: {
    startIpAddress: '0.0.0.0' // TODO: Reduce to only Web App IP
    endIpAddress: '255.255.255.255'
  }
}
resource database 'Microsoft.DBforMariaDB/servers/databases@2018-06-01' = {
  parent: mariaDb
  name: 'bitnami_drupal' // TODO: Extract to config file
  properties: {}
}

// App Service Plan

resource serverFarm 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: ''
  location: location
  properties: {
    reserved: true
  }
  kind: 'linux'
  sku: {
    name: 'P1v3'
  }
}

// Web App for Containers
resource site 'Microsoft.Web/sites@2022-03-01' = {
  name: ''
  location: location
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|bitnami/drupal-nginx:latest'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '1200'
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
          value: 'bitnami_drupal'
        }
        {
          name: 'DRUPAL_DATABASE_USER'
          value: '' // TODO: Extract to config file
        }
        {
          name: 'DRUPAL_DATABASE_PASSWORD'
          value: '' // TODO: Extract to config file
        }
      ]
    }
  }
}
resource mount 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: site
  name: 'azurestorageaccounts'
  properties: {
    '${fileShare.name}': {
      type: 'AzureFiles'
      shareName: fileShare.name
      mountPath: '/bitnami/drupal'
      accountName: storageAccount.name
      accessKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
    }
  }
}

// ---------
// Variables
// ---------

var defaults = loadJsonContent('../../defaults.json')

var location = config.location

// ----------
// Parameters
// ----------

param config object
