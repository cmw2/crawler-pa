@description('The name of the Document Intelligence service.')
param name string

@description('The location of the Document Intelligence service.')
param location string = resourceGroup().location

@description('The SKU name of the Document Intelligence service.')
@allowed(['S0', 'S1', 'S2', 'S3'])
param sku string = 'S0'

@description('Tags for the Document Intelligence service.')
param tags object = {}

@description('The name of the Key Vault to store the document intelligence key.')
param keyVaultName string = ''

@description('The resource group where the Key Vault is located.')
param keyVaultResourceGroup string = resourceGroup().name

@description('The name of the secret to store the document intelligence key in the Key Vault.')
param keySecretName string = 'form-recognizer-key'


resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  sku: {
    name: sku
  }
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Save the document intelligence key to the KeyVault if a KeyVault name is provided
module docIntelligenceKeySecret '../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-doc-intelligence-key-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: keySecretName
    contentType: 'text/plain'
    secretValue: documentIntelligence.listKeys().key1
    tags: tags
  }
}
@description('The Document Intelligence service name.')
output name string = documentIntelligence.name

@description('The Document Intelligence service endpoint.')
output endpoint string = documentIntelligence.properties.endpoint

@description('The Document Intelligence service resource ID.')
output id string = documentIntelligence.id

output keySecretName string = !empty(keyVaultName) ? keySecretName : ''
