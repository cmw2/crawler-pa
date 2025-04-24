@description('The name of the Document Intelligence service.')
param name string

@description('The location of the Document Intelligence service.')
param location string = resourceGroup().location

@description('The SKU name of the Document Intelligence service.')
@allowed(['S0', 'S1', 'S2', 'S3'])
param sku string = 'S0'

@description('Tags for the Document Intelligence service.')
param tags object = {}

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

@description('The Document Intelligence service name.')
output name string = documentIntelligence.name

@description('The Document Intelligence service endpoint.')
output endpoint string = documentIntelligence.properties.endpoint

@description('The Document Intelligence service resource ID.')
output id string = documentIntelligence.id
