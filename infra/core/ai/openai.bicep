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

@description('The name of the Key Vault to store the OpenAI key.')
param keyVaultName string = ''

@description('The resource group where the Key Vault is located.')
param keyVaultResourceGroup string = resourceGroup().name

@description('The name of the secret to store the OpenAI key in the Key Vault.')
param keySecretName string = 'embedding-model-key'

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

// Save the OpenAI key to the KeyVault if a KeyVault name is provided
module openAIKeySecret '../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-openai-key-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: keySecretName
    contentType: 'text/plain'
    secretValue: openAI.listKeys().key1
    tags: tags
  }
}

@description('The Azure OpenAI service name.')
output name string = openAI.name

@description('The Azure OpenAI service endpoint.')
output endpoint string = openAI.properties.endpoint

@description('The Azure OpenAI service resource ID.')
output id string = openAI.id

output keySecretName string = !empty(keyVaultName) ? keySecretName : ''

