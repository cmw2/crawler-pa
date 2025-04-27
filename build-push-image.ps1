# Stop on error
$ErrorActionPreference = 'Stop'

# Get environment variables needed for the Docker image
$RESOURCE_GROUP = $env:AZURE_RESOURCE_GROUP_NAME
$LOCATION = $env:AZURE_LOCATION
$ACR_NAME = $env:AZURE_CONTAINER_REGISTRY_NAME
$FUNCTION_APP_NAME = $env:CRAWLER_FUNC_NAME

Write-Host "Building and pushing Docker image for $FUNCTION_APP_NAME to $ACR_NAME..."

# If ACR doesn't exist, create it
if (-not (az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP 2>$null)) {
    Write-Host "Creating container registry $ACR_NAME in resource group $RESOURCE_GROUP..."
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true
}

# Get ACR login details
$ACR_USERNAME = az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query username -o tsv
$ACR_PASSWORD = az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "passwords[0].value" -o tsv

# Log in to ACR
Write-Host "Logging in to ACR..."
az acr login --name $ACR_NAME

# Build and push the image
$REGISTRY_URL = "$ACR_NAME.azurecr.io"
$IMAGE_NAME = "$REGISTRY_URL/$FUNCTION_APP_NAME`:latest"

Write-Host "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

Write-Host "Pushing Docker image to ACR..."
docker push $IMAGE_NAME

Write-Host "Image built and pushed successfully to $REGISTRY_URL"

# Restart the function app to pick up the new container image
Write-Host "Restarting function app $FUNCTION_APP_NAME to apply changes..."
az functionapp restart --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP

Write-Host "Function app $FUNCTION_APP_NAME restarted successfully."
