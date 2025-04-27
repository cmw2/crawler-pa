metadata description = 'Creates an Azure Key Vault.'
param name string
param location string = resourceGroup().location
param tags object = {}

@description('Array of principal IDs that will have read permissions to the key vault')
param readAccessPrincipalIds array = []

@description('Array of principal IDs that will have read/write permissions to the key vault')
param readWriteAccessPrincipalIds array = []

@description('Allow the key vault to be used during resource creation.')
param enabledForDeployment bool = false
@description('Allow the key vault to be used for template deployment.')
param enabledForTemplateDeployment bool = false

var readPermissions = {
  secrets: ['get', 'list']
}

var readWritePermissions = {
  secrets: ['get', 'list', 'set', 'delete']
}

// Generate access policies for read-only principals
var readAccessPolicies = [for principalId in readAccessPrincipalIds: {
  objectId: principalId
  permissions: readPermissions
  tenantId: subscription().tenantId
}]

// Generate access policies for read-write principals
var readWriteAccessPolicies = [for principalId in readWriteAccessPrincipalIds: {
  objectId: principalId
  permissions: readWritePermissions
  tenantId: subscription().tenantId
}]

// Combine all access policies
var accessPolicies = concat(readAccessPolicies, readWriteAccessPolicies)

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: accessPolicies
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
  }
}

output endpoint string = keyVault.properties.vaultUri
output id string = keyVault.id
output name string = keyVault.name
