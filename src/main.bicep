// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './modules/groups/resources.bicep' = {
  name: 'Microsoft.Resources'
  scope: subscription(settings.subscriptionId)
  params: {
    defaults: defaults
    settings: settings
  }
}

module components './modules/components/resources.bicep' = {
  name: 'Microsoft.Resources'
  scope: resourceGroup(settings.resourceGroup.name)
  params: {
    defaults: defaults
    settings: settings
    username: username
    password: password
  }
  dependsOn: [
    groups
  ]
}

// ---------
// Variables
// ---------

var defaults = loadJsonContent('defaults.json')

// ----------
// Parameters
// ----------

param settings object

@secure()
param username string
@secure()
param password string
