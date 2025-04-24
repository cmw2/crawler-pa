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

@description('The Azure AI Search service name.')
output name string = search.name

@description('The Azure AI Search service endpoint.')
output endpoint string = 'https://${search.name}.search.windows.net'

@description('The Azure AI Search service resource ID.')
output id string = search.id
