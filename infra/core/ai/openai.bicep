@description('The name of the Azure OpenAI service.')
param name string

@description('The location of the Azure OpenAI service.')
param location string = resourceGroup().location

@description('The SKU name of the Azure OpenAI service.')
@allowed(['S0'])
param sku string = 'S0'

@description('Tags for the Azure OpenAI service.')
param tags object = {}

@description('Array of model deployments to create.')
param deployments array = []

resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for deployment in deployments: {
  name: deployment.name
  parent: openAI
  sku: deployment.?sku ?? {
    name: 'Standard'
    capacity: deployment.?capacity ?? 1
  }
  properties: {
    model: deployment.model
    raiPolicyName: deployment.?raiPolicyName ?? null
  }
}]

@description('The Azure OpenAI service name.')
output name string = openAI.name

@description('The Azure OpenAI service endpoint.')
output endpoint string = openAI.properties.endpoint

@description('The Azure OpenAI service resource ID.')
output id string = openAI.id



