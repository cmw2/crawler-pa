param()

# Validate required azd environment variables
Write-Host "Validating required azd environment variables..." -ForegroundColor Cyan

# Function to check if a value from azd env get-value is a valid value or an error message
function Test-AzdEnvVar {
    param (
        [string]$value
    )
    
    # Check if the value contains error text (the error appears after an empty line)
    if ([string]::IsNullOrWhiteSpace($value) -or $value -match "ERROR: key .+ not found") {
        return $false
    }
    return $true
}

# Get values and properly handle errors in stdout
$rawBaseUrls = azd env get-value BASE_URLS 2>$null
$baseUrls = if (Test-AzdEnvVar -value $rawBaseUrls) { $rawBaseUrls } else { "" }

$rawCrawlUrls = azd env get-value CRAWL_URLS 2>$null
$crawlUrls = if (Test-AzdEnvVar -value $rawCrawlUrls) { $rawCrawlUrls } else { "" }

# Show values for debugging if they exist
if (-not [string]::IsNullOrWhiteSpace($baseUrls)) {
    Write-Host "BASE_URLS is set to: $baseUrls" -ForegroundColor Green
}

if (-not [string]::IsNullOrWhiteSpace($crawlUrls)) {
    Write-Host "CRAWL_URLS is set to: $crawlUrls" -ForegroundColor Green
}

# Validate that at least one is set
if ([string]::IsNullOrWhiteSpace($baseUrls) -and [string]::IsNullOrWhiteSpace($crawlUrls)) {
    Write-Host "Error: At least one of BASE_URLS or CRAWL_URLS must be provided in the azd environment." -ForegroundColor Red
    Write-Host "Please set one of these variables using 'azd env set BASE_URLS <value>' or 'azd env set CRAWL_URLS <value>'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ azd environment variable validation successful" -ForegroundColor Green

# Get current user's Object ID
Write-Host "Getting current user's Object ID..." -ForegroundColor Cyan
$userObjectId = az ad signed-in-user show --query id -o tsv

if ([string]::IsNullOrWhiteSpace($userObjectId)) {
    Write-Host "Could not determine current user's Object ID. Are you logged in with 'az login'?" -ForegroundColor Red
    exit 1
}

# Save to azd environment
Write-Host "Setting deploymentPrincipalId parameter for Bicep template..." -ForegroundColor Cyan
azd env set AZURE_DEPLOYER_PRINCIPAL_ID $userObjectId

Write-Host "✅ Successfully captured current user's Object ID: $userObjectId" -ForegroundColor Green
