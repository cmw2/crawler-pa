metadata description = 'Creates an Azure Cosmos DB account.'
param name string
param location string = resourceGroup().location
param tags object = {}

@description('The name of the Key Vault to store the document intelligence key.')
param keyVaultName string = ''

@description('The resource group where the Key Vault is located.')
param keyVaultResourceGroup string = resourceGroup().name

@description('The name of the secret to store the document intelligence key in the Key Vault.')
param keySecretName string = 'cosmos-key'

@description('The name of the secret to store the document intelligence connection string in the Key Vault.')
param connectionStringSecretName string = 'AZURE-COSMOS-CONNECTION-STRING'

@allowed([ 'GlobalDocumentDB', 'MongoDB', 'Parse' ])
param kind string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: name
  kind: kind
  location: location
  tags: tags
  properties: {
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    apiProperties: (kind == 'MongoDB') ? { serverVersion: '4.2' } : {}
    capabilities: [ { name: 'EnableServerless' } ]
    minimalTlsVersion: 'Tls12'
  }
}

// Save the cosmos account connection string to the KeyVault if a KeyVault name is provided
module cosmosConnectionStringSecret '../../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-cosmos-connection-string-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: connectionStringSecretName
    contentType: 'text/plain'
    secretValue: cosmos.listConnectionStrings().connectionStrings[0].connectionString
    tags: tags
  }
}

module cosmosKeySecret '../../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-cosmos-key-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: keySecretName
    contentType: 'text/plain'
    secretValue: cosmos.listKeys().primaryMasterKey
    tags: tags
  }
}

// output connectionStringKey string = connectionStringKey
output endpoint string = cosmos.properties.documentEndpoint
output id string = cosmos.id
output name string = cosmos.name
output keySecretName string = !empty(keyVaultName) ? keySecretName : ''
output connectionStringSecretName string = !empty(keyVaultName) ? connectionStringSecretName : ''
