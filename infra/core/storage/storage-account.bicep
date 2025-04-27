@description('Name of the storage account')
param name string

@description('Location to deploy the storage account')
param location string = resourceGroup().location

@description('Tags to apply to the storage account')
param tags object = {}

@description('Storage Account SKU')
param sku object = {
  name: 'Standard_LRS'
}

@description('Storage Account Kind')
@allowed(['Storage', 'StorageV2', 'BlobStorage', 'FileStorage', 'BlockBlobStorage'])
param kind string = 'StorageV2'

@description('Allow or disallow public access to all blobs or containers in the storage account')
param allowBlobPublicAccess bool = false

@description('Allow or disallow cross AAD tenant object replication')
param allowCrossTenantReplication bool = false

@description('Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key')
param allowSharedKeyAccess bool = true

@description('Set the minimum TLS version to be permitted on requests to storage')
@allowed(['TLS1_0', 'TLS1_1', 'TLS1_2'])
param minimumTlsVersion string = 'TLS1_2'

@description('Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet')
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}

@description('Enables Hierarchical Namespace for the storage account')
param isHnsEnabled bool = false

@description('The name of the Key Vault to store the storage account connection string.')
param keyVaultName string = ''

@description('The resource group where the Key Vault is located.')
param keyVaultResourceGroup string = resourceGroup().name

@description('The name of the secret to store the storage account connection string in the Key Vault.')
param connectionStringSecretName string = 'storage-connection-string'


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: kind
  properties: {
    accessTier: (kind == 'StorageV2' || kind == 'BlockBlobStorage') ? 'Hot' : null
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    isHnsEnabled: isHnsEnabled
    minimumTlsVersion: minimumTlsVersion
    networkAcls: networkAcls
    supportsHttpsTrafficOnly: true
  }
}

// Save the storage connection string to the KeyVault if a KeyVault name is provided
module storageConnectionStringSecret '../security/keyvault-secret.bicep' = if (!empty(keyVaultName)) {
  name: '${name}-storage-connection-string-secret'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    keyVaultName: keyVaultName
    name: connectionStringSecretName
    contentType: 'text/plain'
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    tags: tags
  }
}


@description('The name of the storage account')
output name string = storageAccount.name

@description('The resource ID of the storage account')
output id string = storageAccount.id

@description('The storage account primary endpoint for blobs')
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('The storage account primary endpoint for files')
output fileEndpoint string = storageAccount.properties.primaryEndpoints.file

@description('The storage account primary endpoint for tables')
output tableEndpoint string = storageAccount.properties.primaryEndpoints.table

@description('The storage account primary endpoint for queues')
output queueEndpoint string = storageAccount.properties.primaryEndpoints.queue

output secretName string = !empty(keyVaultName) ? connectionStringSecretName : ''

