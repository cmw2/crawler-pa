#!/bin/bash

# Simple script to build and push Docker image to Azure Container Registry using az acr build
# This avoids local Docker build and uses ACR's remote build capability

set -e  # Exit immediately if a command exits with a non-zero status

echo "========================================="
echo "   Building and Pushing Docker Image    "
echo "========================================="

# Check if the Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed."
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
echo "Checking Azure CLI login status..."
az account show &> /dev/null || {
    echo "You are not logged in to Azure CLI."
    echo "Please run 'az login' first."
    exit 1
}

# Get ACR name from azd environment
echo "Getting ACR information from azd environment..."
ACR_NAME=$(azd env get-values | grep CONTAINER_REGISTRY_NAME | cut -d= -f2 | sed 's/^"\(.*\)"$/\1/')

# If ACR name not found in azd environment, prompt user
if [ -z "$ACR_NAME" ]; then
    echo "No ACR found in azd environment."
    echo "Please enter your ACR name:"
    read -p "ACR Name: " ACR_NAME
    
    if [ -z "$ACR_NAME" ]; then
        echo "No ACR name provided. Exiting."
        exit 1
    fi
fi

echo "Using ACR: $ACR_NAME"

# Version generation
# Get the date in YYYYMMDD format
DATE_TAG=$(date +"%Y%m%d")

# If git is available and we're in a git repo, get the short commit hash
GIT_TAG=""
if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
    GIT_TAG=$(git rev-parse --short HEAD)
fi

# Create version tag
if [ -n "$GIT_TAG" ]; then
    # If git info is available, use date + git hash
    VERSION_TAG="${DATE_TAG}-${GIT_TAG}"
else
    # If no git, just use date + random string
    RANDOM_SUFFIX=$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)
    VERSION_TAG="${DATE_TAG}-${RANDOM_SUFFIX}"
fi

echo "Using version tag: $VERSION_TAG"

# Create a temporary directory for the build context
echo "Creating optimized build context..."
TEMP_DIR=$(mktemp -d)
ORIG_DIR=$(pwd)

# Copy files to the temporary directory, excluding patterns from .dockerignore
if [ -f ".dockerignore" ]; then
    echo "Using exclusions from .dockerignore"
    rsync -a --exclude-from=.dockerignore . "$TEMP_DIR/"
else
    # Default exclusions if no .dockerignore exists
    rsync -a --exclude=".git" --exclude="env" --exclude=".venv" --exclude="venv" --exclude="__pycache__" . "$TEMP_DIR/"
fi

# Change to the temporary directory
cd "$TEMP_DIR"

# Allow specification of additional tags via command-line arguments
ADDITIONAL_TAGS=""
IMAGE_NAME="crawler/crawler"
VERSION_ARG=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tag|-t)
            ADDITIONAL_TAGS="$ADDITIONAL_TAGS --tag ${IMAGE_NAME}:$2"
            shift 2
            ;;
        --version|-v)
            VERSION_TAG="$2"
            shift 2
            ;;
        --major)
            VERSION_ARG="major"
            shift
            ;;
        --minor)
            VERSION_ARG="minor"
            shift
            ;;
        --patch)
            VERSION_ARG="patch"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --tag, -t TAG     Add a specific tag (can be used multiple times)"
            echo "  --version, -v VER Specify a version tag explicitly"
            echo "  --major           Bump the major version"
            echo "  --minor           Bump the minor version"
            echo "  --patch           Bump the patch version"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# If version tracking file exists and we have a version arg, update the version
VERSION_FILE="${ORIG_DIR}/.version"
if [[ -n "$VERSION_ARG" ]]; then
    if [[ -f "$VERSION_FILE" ]]; then
        CURRENT_VERSION=$(cat "$VERSION_FILE")
        IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
        
        if [[ "$VERSION_ARG" == "major" ]]; then
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
        elif [[ "$VERSION_ARG" == "minor" ]]; then
            MINOR=$((MINOR + 1))
            PATCH=0
        elif [[ "$VERSION_ARG" == "patch" ]]; then
            PATCH=$((PATCH + 1))
        fi
        
        VERSION_TAG="${MAJOR}.${MINOR}.${PATCH}"
    else
        # Default start version
        if [[ "$VERSION_ARG" == "major" ]]; then
            VERSION_TAG="1.0.0"
        elif [[ "$VERSION_ARG" == "minor" ]]; then
            VERSION_TAG="0.1.0"
        elif [[ "$VERSION_ARG" == "patch" ]]; then
            VERSION_TAG="0.0.1"
        fi
    fi
    
    # Save the new version
    echo "$VERSION_TAG" > "$VERSION_FILE"
    echo "Updated semantic version: $VERSION_TAG"
fi

# Build and push the image with both latest and versioned tags
echo "Building and pushing image to ACR..."
echo "Running: az acr build --registry $ACR_NAME --image ${IMAGE_NAME}:latest --image ${IMAGE_NAME}:${VERSION_TAG} ${ADDITIONAL_TAGS} --file $ORIG_DIR/Dockerfile ."
az acr build --registry "$ACR_NAME" --image "${IMAGE_NAME}:latest" --image "${IMAGE_NAME}:${VERSION_TAG}" ${ADDITIONAL_TAGS} --file "$ORIG_DIR/Dockerfile" .

# Change back to original directory
cd "$ORIG_DIR"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "========================================="
echo "Image successfully built and pushed to ACR"
echo "  - Tagged as: latest"
echo "  - Tagged as: $VERSION_TAG"
if [ -n "$ADDITIONAL_TAGS" ]; then
    echo "  - With additional tags: $ADDITIONAL_TAGS"
fi
echo "========================================="

# Get function app name from azd environment
echo "Getting Function App information from azd environment..."
FUNCTION_APP=$(azd env get-values | grep FUNCTION_APP_NAME | cut -d= -f2 | sed 's/^"\(.*\)"$/\1/')
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d= -f2 | sed 's/^"\(.*\)"$/\1/')

# If Function App name not found in azd environment, prompt user
if [ -z "$FUNCTION_APP" ]; then
    echo "No Function App found in azd environment."
    echo "Please enter your Function App name:"
    read -p "Function App Name: " FUNCTION_APP
    
    if [ -z "$FUNCTION_APP" ]; then
        echo "No Function App name provided. Skipping restart."
    fi
fi

# If Resource Group not found in azd environment, prompt user
if [ -z "$RESOURCE_GROUP" ]; then
    echo "No Resource Group found in azd environment."
    echo "Please enter your Resource Group name:"
    read -p "Resource Group: " RESOURCE_GROUP
    
    if [ -z "$RESOURCE_GROUP" ]; then
        echo "No Resource Group provided. Skipping restart."
    fi
fi

# Restart the function app to pull the latest image
if [ -n "$FUNCTION_APP" ] && [ -n "$RESOURCE_GROUP" ]; then
    echo "Restarting Function App to pull the latest image..."
    az functionapp restart --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP"
    echo "Function App restart initiated. It may take a moment for changes to take effect."
else
    echo "Skipping Function App restart. Please manually restart your Function App to pull the latest image."
fi

echo "Build and push process completed successfully!"
echo "========================================="
