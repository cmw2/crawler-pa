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

// @description('Endpoint of existing Document Intelligence service. Required if useExistingDocIntelligence is true.')
// param existingDocIntelligenceEndpoint string = ''

// @description('Key of existing Document Intelligence service. Required if useExistingDocIntelligence is true.')
// param existingDocIntelligenceKey string = ''

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

// @description('Endpoint of existing Azure OpenAI service. Required if useExistingOpenAI is true.')
// param existingOpenAIEndpoint string = ''

// @description('Key of existing Azure OpenAI service. Required if useExistingOpenAI is true.')
// param existingOpenAIKey string = ''


@description('Deployment name for the text embeddings model.  Defaults to the name of the model.')
param openAIEmbeddingDeploymentName string = openAIEmbeddingModelName

@description('Model to use for text embeddings.')
param openAIEmbeddingModelName string = 'text-embedding-3-large'

@description('Deployment model version for the text embeddings model.')
param openAIEmbeddingModelVersion string = '1'

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

// @description('Endpoint of existing Azure AI Search service. Required if useExistingAISearch is true.')
// param existingSearchEndpoint string = ''

// @description('Key of existing Azure AI Search service. Required if useExistingAISearch is true.')
// param existingSearchKey string = ''

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

// @description('Endpoint URL of existing Cosmos DB account. Required if createNewCosmosDB is false.')
// param existingCosmosDBUrl string = ''

// @description('Key of existing Cosmos DB account. Required if createNewCosmosDB is false.')
// param existingCosmosDBKey string = ''

@description('Database name for Cosmos DB.')
param cosmosDBDatabaseName string = 'CrawlStore'

@description('Container name for Cosmos DB to store crawler logs.')
param cosmosDBContainerName string = 'URLChangeLog'

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
    
// If useExistingACR is true, use acrName parameter
// If useExistingACR is false, use acrName if provided, otherwise use default name pattern
var containerRegistryResourceName = useExistingACR 
  ? acrName 
  : !empty(acrName) 
    ? acrName 
    : '${abbrs.containerRegistryRegistries}${environmentName}${resourceToken}'

// AI Services names
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

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupResourceName
  location: location
  tags: tags
}

// Azure Container Registry
// Use existing:
resource existingAcr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (useExistingACR) {
  name: containerRegistryResourceName
  scope: resourceGroup(existingACRResourceGroup)
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
  }
}

// Azure Document Intelligence
resource existingDocIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (useExistingDocIntelligence) {
  name: docIntelligenceResourceName
  scope: resourceGroup(existingDocIntelligenceResourceGroup)
}

module documentIntelligence './core/ai/document-intelligence.bicep' = if (!useExistingDocIntelligence) {
  name: 'document-intelligence'
  scope: rg
  params: {
    name: docIntelligenceResourceName
    location: location
    tags: tags
    sku: docIntelligenceSku
  }
}

// Azure OpenAI
resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (useExistingOpenAI) {
  name: openAIResourceName
  scope: resourceGroup(existingOpenAIResourceGroup)
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
  }
}

// Module for Azure AI Search
resource existingSearch 'Microsoft.Search/searchServices@2023-11-01' existing = if (useExistingAISearch) {
  name: searchServiceResourceName
  scope: resourceGroup(existingAISearchResourceGroup)
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
  }
}

// Module for Azure Cosmos DB
resource existingCosmosDB 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = if (useExistingCosmosDBAccount) {
  name: cosmosDBAccountResourceName
  scope: resourceGroup(existingCosmosDBAccountResourceGroup)
}
module cosmosDB 'core/database/cosmos/cosmos-account.bicep' = if (!useExistingCosmosDBAccount) {
  name: 'cosmos-db'
  scope: rg
  params: {
    name: cosmosDBAccountResourceName
    kind: 'GlobalDocumentDB'
    location: location
    tags: tags
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
      // Basic configuration settings
      BASE_URLS: ''  // Will need to be configured post-deployment
      INCLUDE_PATHS: ''  // Will need to be configured post-deployment
      EXCLUDE_LIST: 'www.google.com'  // Default value from .env
      ENABLE_VECTORS: 'true'
      EXTRACT_LINK_TYPE: 'pdf'
      NUM_OF_THREADS: '2'
      INDEX_NAME: searchIndexName
      // COSMOS_DATABASE_NAME: cosmosDBDatabaseName
      // COSMOS_CONTAINER_NAME: cosmosDBContainerName // this might not be used by the code yet
      
      // Docker registry settings
      DOCKER_REGISTRY_SERVER_URL: 'https://${useExistingACR ? existingAcr.properties.loginServer : acr.outputs.loginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: useExistingACR ? existingAcr.listCredentials().username : listCredentials(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.ContainerRegistry/registries', containerRegistryResourceName), '2023-07-01').username
      DOCKER_REGISTRY_SERVER_PASSWORD: useExistingACR ? existingAcr.listCredentials().passwords[0].value : listCredentials(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.ContainerRegistry/registries', containerRegistryResourceName), '2023-07-01').passwords[0].value
      
      // Storage settings
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
      // WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: useExistingStorageAccount 
      //   ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResourceName};AccountKey=${existingStorageAccount.listKeys().keys[0].value}' 
      //   : 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResourceName};AccountKey=${listKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.Storage/storageAccounts', storageAccountResourceName), '2023-01-01').keys[0].value}'
      // WEBSITE_CONTENTSHARE: toLower(functionAppResourceName)
      AzureWebJobsStorage: useExistingStorageAccount 
        ? 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${existingStorageAccount.listKeys().keys[0].value}' 
        : 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.outputs.name};AccountKey=${listKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.Storage/storageAccounts', storageAccountResourceName), '2023-01-01').keys[0].value}'
      
      // Search settings
      SEARCH_ENDPOINT: useExistingAISearch ? 'https://${aiSearchName}.search.windows.net' : search.outputs.endpoint
      SEARCH_KEY: useExistingAISearch 
        ? existingSearch.listAdminKeys().primaryKey 
        : listAdminKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.Search/searchServices', searchServiceResourceName), '2023-11-01').primaryKey
      
      // Document Intelligence settings
      FORM_RECOGNIZER_ENDPOINT: useExistingDocIntelligence ? existingDocIntelligence.properties.endpoint : documentIntelligence.outputs.endpoint
      FORM_RECOGNIZER_KEY: useExistingDocIntelligence 
        ? existingDocIntelligence.listKeys().key1 
        : listKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.CognitiveServices/accounts', docIntelligenceResourceName), '2023-05-01').key1
      
      // OpenAI settings
      EMBEDDING_MODEL_ENDPOINT: useExistingOpenAI 
        ? '${existingOpenAI.properties.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings' 
        : '${openAI.outputs.endpoint}openai/deployments/${openAIEmbeddingDeploymentName}/embeddings'
      EMBEDDING_MODEL_KEY: useExistingOpenAI 
        ? existingOpenAI.listKeys().key1 
        : listKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.CognitiveServices/accounts', openAIResourceName), '2023-05-01').key1
      
      // Cosmos DB settings
      COSMOS_URL: useExistingCosmosDBAccount ? existingCosmosDB.properties.documentEndpoint : cosmosDB.outputs.endpoint
      COSMOS_DB_KEY: useExistingCosmosDBAccount 
        ? existingCosmosDB.listKeys().primaryMasterKey 
        : listKeys(resourceId(subscription().subscriptionId, rg.name, 'Microsoft.DocumentDB/databaseAccounts', cosmosDBAccountResourceName), '2023-11-15').primaryMasterKey
        
      // Application Insights settings
      //APPLICATIONINSIGHTS_CONNECTION_STRING: ''  // Will need to be configured post-deployment
      
      // Azure AD / Service Principal settings (if using service principal authentication)
      // AZURE_TENANT_ID: ''  // Will need to be configured post-deployment
      // AZURE_CLIENT_ID: ''  // Will need to be configured post-deployment
      // AZURE_CLIENT_SECRET: ''  // Will need to be configured post-deployment
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

