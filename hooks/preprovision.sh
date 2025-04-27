#!/bin/bash
set -e

# Validate required azd environment variables
echo "Validating required azd environment variables..."

# Function to check if value from azd env get-value is valid or an error message
check_azd_env_var() {
    local value="$1"
    
    # Check if the value contains error text (typically on second line after empty line)
    if [ -z "$value" ] || echo "$value" | grep -q "ERROR: key .* not found"; then
        echo ""
    else
        echo "$value"
    fi
}

# Get values safely and check for error messages in stdout
BASE_URLS_RAW=$(azd env get-value BASE_URLS 2>/dev/null || echo "")
BASE_URLS=$(check_azd_env_var "$BASE_URLS_RAW")

CRAWL_URLS_RAW=$(azd env get-value CRAWL_URLS 2>/dev/null || echo "")
CRAWL_URLS=$(check_azd_env_var "$CRAWL_URLS_RAW")

# Show values for debugging if they exist
if [ -n "$BASE_URLS" ]; then
    echo "BASE_URLS is set to: $BASE_URLS"
fi

if [ -n "$CRAWL_URLS" ]; then
    echo "CRAWL_URLS is set to: $CRAWL_URLS"
fi

# Validate that at least one is set
if [ -z "$BASE_URLS" ] && [ -z "$CRAWL_URLS" ]; then
    echo "Error: At least one of BASE_URLS or CRAWL_URLS must be provided in the azd environment."
    echo "Please set one of these variables using 'azd env set BASE_URLS <value>' or 'azd env set CRAWL_URLS <value>'"
    exit 1
fi

echo "✅ azd environment variable validation successful"

# Get current user's Object ID
echo "Getting current user's Object ID..."
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv | tr -d '\r\n')

if [ -z "$USER_OBJECT_ID" ]; then
  echo "Could not determine current user's Object ID. Are you logged in with 'az login'?"
  exit 1
fi

# Save to azd environment
echo "Setting deploymentPrincipalId parameter for Bicep template..."
azd env set AZURE_DEPLOYER_PRINCIPAL_ID "$USER_OBJECT_ID"

echo "✅ Successfully captured current user's Object ID: $USER_OBJECT_ID"

