@description('The name of the Azure AI Search service.')
param name string

@description('The location of the Azure AI Search service.')
param location string = resourceGroup().location

@description('The SKU name of the Azure AI Search service.')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3'])
param sku string = 'standard'

@description('Tags for the Azure AI Search service.')
param tags object = {}

@description('Enables semantic search capability.')
@allowed(['disabled', 'free', 'standard'])
param semanticSearch string = 'disabled'

@description('The name of the Key Vault to store the search key.')
param keyVaultName string = ''

@description('The resource group where the Key Vault is located.')
param keyVaultResourceGroup string = resourceGroup().name

@description('The name of the secret to store the search key in the Key Vault.')
param searchKeySecretName string = 'search-key'

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    semanticSearch: semanticSearch
    publicNetworkAccess: 'enabled'
  }
}

// Save the search key to the KeyVault if a KeyVault name is provided
module searchKeySecret '../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-search-key-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: searchKeySecretName
    contentType: 'text/plain'
    secretValue: search.listAdminKeys().primaryKey
    tags: tags
  }
}

@description('The Azure AI Search service name.')
output name string = search.name

@description('The Azure AI Search service endpoint.')
output endpoint string = 'https://${search.name}.search.windows.net'

@description('The Azure AI Search service resource ID.')
output id string = search.id

@description('The secret name where the search key is stored in the Key Vault.')
output secretName string = !empty(keyVaultName) ? searchKeySecretName : ''
