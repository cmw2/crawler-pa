targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

// Add parameter for deploying user's object ID
@description('Object ID of the current user or service principal deploying the template. This user will be granted access to Key Vault.')
param deploymentPrincipalId string = ''

// Crawler configuration parameters
@description('Comma-separated list of base URLs to crawl. At least one of baseUrls or crawlUrls must be provided.')
param baseUrls string = ''

@description('Comma-separated list of specific URLs to crawl without following links. At least one of baseUrls or crawlUrls must be provided.')
param crawlUrls string = ''

@description('Comma-separated list of domains to include in the crawl.')
param includeDomains string = ''

@description('Regex patterns for domains to include, separated by pipe characters (|).')
param includeDomainsRegex string = ''

@description('Comma-separated list of URLs to include in the crawl.')
param includeUrls string = ''

@description('Regex patterns for URLs to include, separated by pipe characters (|).')
param includeUrlsRegex string = ''

@description('Comma-separated list of URLs to exclude from the crawl.')
param excludeList string = 'www.google.com'

@description('Comma-separated list of file types to extract links for (e.g., pdf).')
param extractLinkType string = 'pdf'

@description('Maximum crawl depth for following links from base URLs.')
param crawlDepth int = 2

@description('Number of threads to use for crawling.')
param numOfThreads int = 2

@description('Delay in seconds between crawling URLs.')
param crawlDelay int = 0

@description('Batch size for the indexer when uploading documents.')
param indexerBatchSize int = 100

@description('Whether to enable vector embeddings for search.')
param enableVectors bool = true

@description('Whether to ignore anchor links when crawling.')
param ignoreAnchorLink bool = true

@description('User agent string for the crawler.')
param agentName string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0'

// Key Vault Parameters
@description('Flag to use an existing Key Vault.')
param useExistingKeyVault bool = false

@description('Resource group of existing Key Vault. Required if useExistingKeyVault is true.')
param existingKeyVaultResourceGroup string = ''

@description('Name of Key Vault. Required if useExistingKeyVault is true, optional if creating a new service.')
param keyVaultName string = ''

// Container Registry Parameters
@description('Flag to use an existing Azure Container Registry.  If false one will be created.')
param useExistingACR bool = false

@description('Resource group of existing Azure Container Registry. Required if useExistingACR is true.')
param existingACRResourceGroup string = ''

@description('Name of Azure Container Registry. Required if useExistingACR is true, optional if creating a new service.')
param acrName string = ''

@description('Admin user enabled for the Azure Container Registry. Only applicable if creating a new service.')
param acrAdminUserEnabled bool = true

// Function App & App Service Plan Parameters
@description('Name of Function App. Optional.')
param functionAppName string = ''

// Storage Account Parameters
@description('Flag to use an existing Storage Account.')
param useExistingStorageAccount bool = false

@description('Resource group of existing Storage Account. Required if useExistingStorageAccount is true.')
param existingStorageAccountResourceGroup string = ''

@description('Name of Storage Account. Required if useExistingStorageAccount is true, optional if creating a new service.')
param storageAccountName string = ''

@description('Flag to use an existing App Service Plan.')
param useExistingAppServicePlan bool = false

@description('Resource group of existing App Service Plan. Required if useExistingAppServicePlan is true.')
param existingAppServicePlanResourceGroup string = ''

@description('Name of App Service Plan. Required if useExistingAppServicePlan is true, optional if creating a new service.')
param appServicePlanName string = ''

@description('SKU name for the App Service Plan. Only applicable if creating a new App Service Plan.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param appServicePlanSku string = 'S1'

// Document Intelligence Parameters
@description('Flag to use an existing Document Intelligence service or create a new one.')
param useExistingDocIntelligence bool = false

@description('Resource group of existing Document Intelligence. Required if useExistingDocIntelligence is true.')
param existingDocIntelligenceResourceGroup string = ''

@description('Name of Document Intelligence. Required if existingDocIntelligenceResourceGroup is true, optional if creating a new service.')
param docIntelligenceName string = ''

@description('SKU name for the Document Intelligence service. Only applicable if creating a new service.')
@allowed(['S0', 'S1', 'S2', 'S3'])
param docIntelligenceSku string = 'S0'

// Azure OpenAI Parameters
@description('Flag to use exsiting Azure OpenAI service or create a new one.')
param useExistingOpenAI bool = false

@description('Resource group of existing Azure OpenAI Service. Required if useExistingOpenAI is true.')
param existingOpenAIResourceGroup string = ''

@description('Name of Azure OpenAI Service. Required if useExistingOpenAI is true, optional if creating a new service.')
param openAIName string = ''

@description('SKU name for the Azure OpenAI service. Only applicable if creating a new service.')
@allowed(['S0'])
param openAISku string = 'S0'

@description('Deployment name for the text embeddings model.  Defaults to the name of the model.')
param openAIEmbeddingDeploymentName string = openAIEmbeddingModelName

@description('Model to use for text embeddings.')
param openAIEmbeddingModelName string = 'text-embedding-ada-002'

@description('Deployment model version for the text embeddings model.')
param openAIEmbeddingModelVersion string = '2'

param openAIEmbeddingTPM int = 60

// Azure AI Search Parameters
@description('Flag to create a new Azure AI Search service or use existing one.')
param useExistingAISearch bool = false

@description('Resource group of existing AI Search Service. Required if useExistingAISearch is true.')
param existingAISearchResourceGroup string = ''

@description('Name of AI Search Service. Required if useExistingAISearch is true, optional if creating a new service.')
param aiSearchName string = ''

@description('SKU name for the Azure AI Search service. Only applicable if creating a new service.')
@allowed(['basic', 'standard', 'standard2', 'standard3'])
param searchSku string = 'basic'

@description('The name of the search index to create.')
param searchIndexName string = 'crawler-index'

// Placeholder for search index field mappings

// Cosmos DB Parameters
@description('Flag to use exsiting Cosmos DB account or create a new one.')
param useExistingCosmosDBAccount bool = false

@description('Resource group of existing Cosmos DB Account. Required if useExistingCosmosDBAccount is true.')
param existingCosmosDBAccountResourceGroup string = ''

@description('Name of Cosmos DB Account. Required if useExistingCosmosDBAccount is true, optional if creating a new service.')
param cosmosDBAccountName string = ''

// Placeholder for the other container needed

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
var resourceToken = toLower(substring(uniqueString(subscription().id, environmentName, location), 0, 5))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource
var apiServiceName = 'crawler-func'


var resourceGroupResourceName = !empty(resourceGroupName) 
  ? resourceGroupName 
  : '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'

var functionAppResourceName = !empty(functionAppName) 
  ? functionAppName 
  : '${abbrs.webSitesFunctions}${environmentName}-${resourceToken}'

var appServicePlanResourceName = useExistingAppServicePlan
  ? appServicePlanName 
  : !empty(appServicePlanName) 
    ? appServicePlanName 
    : '${abbrs.webServerFarms}${environmentName}-${resourceToken}'

var keyVaultResourceName = useExistingKeyVault 
  ? keyVaultName 
  : !empty(keyVaultName) 
    ? keyVaultName 
    : '${abbrs.keyVaultVaults}${environmentName}-${resourceToken}'

var containerRegistryResourceName = useExistingACR 
  ? acrName 
  : !empty(acrName) 
    ? acrName 
    : '${abbrs.containerRegistryRegistries}${environmentName}${resourceToken}'

var docIntelligenceResourceName = useExistingDocIntelligence 
  ? docIntelligenceName 
  : !empty(docIntelligenceName) 
    ? docIntelligenceName 
    : '${abbrs.aiServicesDocumentIntelligence}${environmentName}-${resourceToken}'

var openAIResourceName = useExistingOpenAI 
  ? openAIName 
  : !empty(openAIName) 
    ? openAIName 
    : '${abbrs.aiServicesOpenAI}${environmentName}-${resourceToken}'

var searchServiceResourceName = useExistingAISearch 
  ? aiSearchName 
  : !empty(aiSearchName) 
    ? aiSearchName 
    : '${abbrs.searchSearchServices}${environmentName}-${resourceToken}'

var cosmosDBAccountResourceName = useExistingCosmosDBAccount
  ? cosmosDBAccountName 
  : !empty(cosmosDBAccountName) 
    ? cosmosDBAccountName 
    : '${abbrs.documentDBDatabaseAccounts}${environmentName}-${resourceToken}'

var storageAccountResourceName = useExistingStorageAccount
  ? storageAccountName
  : !empty(storageAccountName)
    ? storageAccountName
    : '${abbrs.storageStorageAccounts}${replace(environmentName, '-', '')}${resourceToken}'

var secretNameAcrUsername = 'CONTAINER-REGISTRY-USERNAME'
var secretNameAcrPassword = 'CONTAINER-REGISTRY-PASSWORD'
var secretNameStorageConnectionString = 'STORAGE-CONNECTION-STRING'
var secretNameDocumentIntelligenceKey = 'DOCUMENT-INTELLIGENCE-KEY'
var secretNameAzureOpenAIKey = 'AZURE-OPENAI-KEY'
var secretNameCosmosDBConnectionString = 'COSMOS-CONNECTION-STRING'
var secretNameCosmosDBKey = 'COSMOS-KEY'
var secretNameSearchKey = 'SEARCH-KEY'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupResourceName
  location: location
  tags: tags
}

// Key Vault
// Use existing:
resource existingKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = if (useExistingKeyVault) {
  name: keyVaultResourceName
  scope: resourceGroup(existingKeyVaultResourceGroup)
}

// Or, define new:
module keyVault './core/security/keyvault.bicep' = if (!useExistingKeyVault) {
  name: 'key-vault'
  scope: rg
  params: {
    name: keyVaultResourceName
    location: location
    tags: tags
    //readAccessPrincipalIds: [functionApp.outputs.identityPrincipalId]
  }
}

var keyVaultReferencePrefix = 'SecretUri=${useExistingKeyVault ? existingKeyVault.properties.vaultUri : keyVault.outputs.endpoint}secrets/'

// Azure Container Registry
// Use existing:
resource existingAcr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (useExistingACR) {
  name: containerRegistryResourceName
  scope: resourceGroup(existingACRResourceGroup)
}

module existingAcrCredentials './core/security/keyvault-secret.bicep' = if (useExistingACR) {
  name: 'existing-acr-username'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameAcrUsername
    contentType: 'text/plain'
    secretValue: existingAcr.listCredentials().username
  }
}

module existingAcrPassword './core/security/keyvault-secret.bicep' = if (useExistingACR) {
  name: 'existing-acr-password'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameAcrPassword
    contentType: 'text/plain'
    secretValue: existingAcr.listCredentials().passwords[0].value
  }
}

// Or, define new:
module acr './core/host/container-registry.bicep' = if (!useExistingACR) {
  name: 'container-registry'
  scope: rg
  params: {
    name: containerRegistryResourceName
    location: location
    tags: tags
    adminUserEnabled: acrAdminUserEnabled
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    usernameSecretName: secretNameAcrUsername
    passwordSecretName: secretNameAcrPassword
  }
}

// App Service Plan
// Use existing:
resource existingAppServicePlan 'Microsoft.Web/serverfarms@2024-04-01' existing = if (useExistingAppServicePlan) {
  name: appServicePlanResourceName
  scope: resourceGroup(existingAppServicePlanResourceGroup)
}

// Or, define new:
module appServicePlan './core/host/appserviceplan.bicep' = if (!useExistingAppServicePlan) {
  name: 'app-service-plan'
  scope: rg
  params: {
    name: appServicePlanResourceName
    location: location
    tags: tags
    sku: {
      name: appServicePlanSku
    }
    kind: 'linux'
    reserved: true
  }
}

// Storage Account
// Use existing:
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if (useExistingStorageAccount) {
  name: storageAccountResourceName
  scope: resourceGroup(existingStorageAccountResourceGroup)
}

module existingstorageConnectionStringSecret './core/security/keyvault-secret.bicep' = if (useExistingStorageAccount) {
  name: 'existing-storage-connection-string'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameStorageConnectionString
    contentType: 'text/plain'
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${existingStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

// Or, define new:
module storageAccount './core/storage/storage-account.bicep' = if (!useExistingStorageAccount) {
  name: 'storage-account'
  scope: rg
  params: {
    name: storageAccountResourceName
    location: location
    tags: tags
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'StorageV2'
    allowSharedKeyAccess: true
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    connectionStringSecretName: secretNameStorageConnectionString
  }
}

// Azure Document Intelligence
resource existingDocIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (useExistingDocIntelligence) {
  name: docIntelligenceResourceName
  scope: resourceGroup(existingDocIntelligenceResourceGroup)
}

module existingDocIntelligenceKeySecret './core/security/keyvault-secret.bicep' = if (useExistingDocIntelligence) {
  name: 'existing-doc-intelligence-key'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameDocumentIntelligenceKey
    contentType: 'text/plain'
    secretValue: existingDocIntelligence.listKeys().key1
  }
}

module documentIntelligence './core/ai/document-intelligence.bicep' = if (!useExistingDocIntelligence) {
  name: 'document-intelligence'
  scope: rg
  params: {
    name: docIntelligenceResourceName
    location: location
    tags: tags
    sku: docIntelligenceSku
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    keySecretName: secretNameDocumentIntelligenceKey
  }
}

// Azure OpenAI
resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (useExistingOpenAI) {
  name: openAIResourceName
  scope: resourceGroup(existingOpenAIResourceGroup)
}

module existingOpenAIKeySecret './core/security/keyvault-secret.bicep' = if (useExistingOpenAI) {
  name: 'existing-openai-key'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameAzureOpenAIKey
    contentType: 'text/plain'
    secretValue: existingOpenAI.listKeys().key1
  }
}

module openAI './core/ai/openai.bicep' = if (!useExistingOpenAI) {
  name: 'openai'
  scope: rg
  params: {
    name: openAIResourceName
    location: location
    tags: tags
    sku: openAISku
    deployments: [
      {
        name: openAIEmbeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: openAIEmbeddingModelName
          version: openAIEmbeddingModelVersion
        }
        capacity: openAIEmbeddingTPM
      }
    ]
    keyVaultName: keyVaultResourceName
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    keySecretName: secretNameAzureOpenAIKey
  }
}

// Module for Azure AI Search
resource existingSearch 'Microsoft.Search/searchServices@2023-11-01' existing = if (useExistingAISearch) {
  name: searchServiceResourceName
  scope: resourceGroup(existingAISearchResourceGroup)
}

module existingSearchKeySecret './core/security/keyvault-secret.bicep' = if (useExistingAISearch) {
  name: 'existing-search-key'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameSearchKey
    contentType: 'text/plain'
    secretValue: existingSearch.listAdminKeys().primaryKey
  }
}

module search './core/ai/search.bicep' = if (!useExistingAISearch) {
  name: 'ai-search'
  scope: rg
  params: {
    name: searchServiceResourceName
    location: location
    tags: tags
    sku: searchSku
    semanticSearch: 'standard'
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    searchKeySecretName: secretNameSearchKey
  }
}

// Module for Azure Cosmos DB
resource existingCosmosDB 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = if (useExistingCosmosDBAccount) {
  name: cosmosDBAccountResourceName
  scope: resourceGroup(existingCosmosDBAccountResourceGroup)
}

module existingCosmosDBConnectionStringSecret './core/security/keyvault-secret.bicep' = if (useExistingCosmosDBAccount) {
  name: 'existing-cosmos-connection-string'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameCosmosDBConnectionString
    contentType: 'text/plain'
    secretValue: existingCosmosDB.listConnectionStrings().connectionStrings[0].connectionString
  }
}

module existingCosmosDBKeySecret './core/security/keyvault-secret.bicep' = if (useExistingCosmosDBAccount) {
  name: 'existing-cosmos-key'
  scope: useExistingKeyVault ? resourceGroup(existingKeyVaultResourceGroup) : rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    name: secretNameCosmosDBKey
    contentType: 'text/plain'
    secretValue: existingCosmosDB.listKeys().primaryMasterKey
  }
}

module cosmosDB 'core/database/cosmos/cosmos-account.bicep' = if (!useExistingCosmosDBAccount) {
  name: 'cosmos-db'
  scope: rg
  params: {
    name: cosmosDBAccountResourceName
    kind: 'GlobalDocumentDB'
    location: location
    tags: tags
    keyVaultName: keyVaultResourceName
    keyVaultResourceGroup: useExistingKeyVault ? existingKeyVaultResourceGroup : rg.name
    keySecretName: secretNameCosmosDBKey
    connectionStringSecretName: secretNameCosmosDBConnectionString
  }
}

// Azure Function App (always define our own)
module functionApp './core/host/functions.bicep' = {
  name: 'function-app'
  scope: rg
  params: {
    name: functionAppResourceName
    location: location
    tags: union(tags, { 'azd-service-name': apiServiceName })
    kind: 'functionapp,linux,container'
    alwaysOn: true
    appServicePlanId: useExistingAppServicePlan ? existingAppServicePlan.id : appServicePlan.outputs.id
    runtimeName: 'custom'
    runtimeVersion: ''
    enableOryxBuild: false
    storageAccountName: useExistingStorageAccount ? existingStorageAccount.name : storageAccount.outputs.name
    linuxFxVersion: 'DOCKER|${useExistingACR ? existingAcr.properties.loginServer : acr.outputs.loginServer}/crawler/crawler:latest'
    appSettings: {
      // Crawler configuration settings
      BASE_URLS: baseUrls
      CRAWL_URLS: crawlUrls
      INCLUDE_DOMAINS: includeDomains
      INCLUDE_DOMAINS_REGEX: includeDomainsRegex
      INCLUDE_URLS: includeUrls
      INCLUDE_URLS_REGEX: includeUrlsRegex
      EXCLUDE_LIST: excludeList
      EXTRACT_LINK_TYPE: extractLinkType
      DEPTH: string(crawlDepth)
      NUM_OF_THREADS: string(numOfThreads)
      DELAY: string(crawlDelay)
      INDEXER_BATCH_SIZE: string(indexerBatchSize)
      ENABLE_VECTORS: enableVectors ? 'true' : 'false'
      IGNORE_ANCHOR_LINK: ignoreAnchorLink ? 'true' : 'false'
      AGENT_NAME: agentName
      
      // Search settings
      INDEX_NAME: searchIndexName
      SEARCH_ENDPOINT: useExistingAISearch ? 'https://${aiSearchName}.search.windows.net' : search.outputs.endpoint
      SEARCH_KEY: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameSearchKey})'
      
      // Document Intelligence settings
      FORM_RECOGNIZER_ENDPOINT: useExistingDocIntelligence ? existingDocIntelligence.properties.endpoint : documentIntelligence.outputs.endpoint
      FORM_RECOGNIZER_KEY: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameDocumentIntelligenceKey})'
      
      // OpenAI settings
      EMBEDDING_MODEL_ENDPOINT: useExistingOpenAI 
        ? '${existingOpenAI.properties.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings' 
        : '${openAI.outputs.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings'
      EMBEDDING_MODEL_KEY: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameAzureOpenAIKey})'
      
      // Cosmos DB settings
      COSMOS_URL: useExistingCosmosDBAccount ? existingCosmosDB.properties.documentEndpoint : cosmosDB.outputs.endpoint
      COSMOS_DB_KEY: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameCosmosDBKey})'
      COSMOS_DATABASE_NAME: 'CrawlStore'
      COSMOS_CONTAINER_NAME: 'URLChangeLog'
      
      // Docker registry settings
      DOCKER_REGISTRY_SERVER_URL: 'https://${useExistingACR ? existingAcr.properties.loginServer : acr.outputs.loginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameAcrUsername})'
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameAcrPassword})'
      
      // Storage settings
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
      AzureWebJobsStorage: '@Microsoft.KeyVault(${keyVaultReferencePrefix}${secretNameStorageConnectionString})'
      
      // Logging settings
      Use_COSMOS_Logger: 'true'
      
      // Schedule for the timer trigger
      SCHEDULE: '0 0 * * *'
    }
    // Enable managed identity for the function app to access Key Vault
    managedIdentity: true
  }
}


// Add Key Vault access policy for the deployment user
module deploymentUserKeyVaultAccess './core/security/keyvault-access.bicep' = if (!empty(deploymentPrincipalId)) {
  name: 'deployment-user-keyvault-access'
  scope: rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    principalId: deploymentPrincipalId
    permissions: {
      secrets: [
        'get'
        'list'
        'set'
        'delete'
      ]
      certificates: [
        'get'
        'list'
        'create'
        'update'
      ]
      keys: [
        'get'
        'list'
        'create'
        'update'
      ]
    }
  }
}

// Add Key Vault access policy for the function app
module functionAppKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'function-app-keyvault-access'
  scope: rg
  params: {
    keyVaultName: useExistingKeyVault ? existingKeyVault.name : keyVault.outputs.name
    principalId: functionApp.outputs.identityPrincipalId
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    }
  }
}

// Add outputs to be referenced by other deployments or for local development
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

// Function App outputs
output FUNCTION_APP_NAME string = functionAppResourceName
output FUNCTION_APP_URL string = functionApp.outputs.uri

// Storage Account outputs
output STORAGE_ACCOUNT_NAME string = storageAccountResourceName

// Container Registry outputs
output CONTAINER_REGISTRY_NAME string = containerRegistryResourceName
output CONTAINER_REGISTRY_LOGIN_SERVER string = useExistingACR ? existingAcr.properties.loginServer : acr.outputs.loginServer

// AI Service outputs
output SEARCH_SERVICE_NAME string = searchServiceResourceName
// TODO: need a way to lookup or at least build not assuming azure commercial
output SEARCH_ENDPOINT string = useExistingAISearch ? 'https://${aiSearchName}.search.windows.net' : search.outputs.endpoint
output FORM_RECOGNIZER_ENDPOINT string = useExistingDocIntelligence ? existingDocIntelligence.properties.endpoint : documentIntelligence.outputs.endpoint
output OPENAI_ENDPOINT string = useExistingOpenAI ? existingOpenAI.properties.endpoint : openAI.outputs.endpoint
output EMBEDDING_MODEL_ENDPOINT string = useExistingOpenAI ? '${existingOpenAI.properties.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings' : '${openAI.outputs.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings'

// Cosmos DB outputs
output COSMOS_DB_URL string = useExistingCosmosDBAccount ? existingCosmosDB.properties.documentEndpoint : cosmosDB.outputs.endpoint

// Key Vault outputs
output KEY_VAULT_NAME string = keyVaultResourceName

