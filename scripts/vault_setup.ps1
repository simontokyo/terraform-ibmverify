# HashiCorp Vault integration for IBM Verify secrets
# This script manages secrets in Vault and retrieves them for Terraform

$ErrorActionPreference = "Stop"

$VAULT_ADDR = if ($env:VAULT_ADDR) { $env:VAULT_ADDR } else { "http://127.0.0.1:8200" }
$VAULT_TOKEN = if ($env:VAULT_TOKEN) { $env:VAULT_TOKEN } else { "root" }
$VAULT_MOUNT = "secret"
$VAULT_PATH = "ibm"

# Export for vault CLI
$env:VAULT_ADDR = $VAULT_ADDR
$env:VAULT_TOKEN = $VAULT_TOKEN

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "IBM Verify - Vault Secret Management" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vault Address: $VAULT_ADDR" -ForegroundColor Yellow
Write-Host ""

# Check if Vault is accessible
function Check-Vault {
    if (-not (Get-Command vault -ErrorAction SilentlyContinue)) {
        Write-Host "Error: vault CLI not found!" -ForegroundColor Red
        Write-Host "Install from: https://www.vaultproject.io/downloads" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or use Docker:" -ForegroundColor Yellow
        Write-Host '  docker run --name vault-dev -d -p 8200:8200 -e "VAULT_DEV_ROOT_TOKEN_ID=root" hashicorp/vault' -ForegroundColor White
        exit 1
    }

    try {
        vault status | Out-Null
    } catch {
        Write-Host "Error: Cannot connect to Vault at $VAULT_ADDR" -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure Vault is running:" -ForegroundColor Yellow
        Write-Host '  docker run --name vault-dev -d -p 8200:8200 -e "VAULT_DEV_ROOT_TOKEN_ID=root" hashicorp/vault' -ForegroundColor White
        exit 1
    }

    Write-Host "✓ Connected to Vault successfully" -ForegroundColor Green
    Write-Host ""
}

# Read secret from Vault
function Read-VaultSecret {
    param($Key)
    
    try {
        $result = vault kv get -field="$Key" "$VAULT_MOUNT/$VAULT_PATH" 2>$null
        return $result
    } catch {
        return ""
    }
}

# Write secret to Vault
function Write-VaultSecret {
    param($Key, $Value)
    
    # Read existing secrets
    try {
        $existing = vault kv get -format=json "$VAULT_MOUNT/$VAULT_PATH" 2>$null | ConvertFrom-Json
        $apiKey = $existing.data.data.ibmcloud_api_key
        $adminUser = $existing.data.data.verify_admin_user
        $adminPass = $existing.data.data.verify_admin_pass
    } catch {
        $apiKey = ""
        $adminUser = ""
        $adminPass = ""
    }
    
    # Build arguments
    $args = @("kv", "put", "$VAULT_MOUNT/$VAULT_PATH")
    if ($apiKey) { $args += "ibmcloud_api_key=$apiKey" } else { $args += "ibmcloud_api_key=" }
    if ($adminUser) { $args += "verify_admin_user=$adminUser" } else { $args += "verify_admin_user=" }
    if ($adminPass) { $args += "verify_admin_pass=$adminPass" } else { $args += "verify_admin_pass=" }
    $args += "$Key=$Value"
    
    & vault $args | Out-Null
}

# Prompt for secret if not in Vault
function Prompt-Secret {
    param($Key, $PromptText, $IsPassword)
    
    $existing = Read-VaultSecret -Key $Key
    
    if ($existing) {
        Write-Host "✓ Found $Key in Vault" -ForegroundColor Green
        return $existing
    }
    
    Write-Host "⚠ $Key not found in Vault" -ForegroundColor Yellow
    Write-Host ""
    
    if ($IsPassword) {
        $secureValue = Read-Host -Prompt $PromptText -AsSecureString
        $value = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue))
    } else {
        $value = Read-Host -Prompt $PromptText
    }
    
    if (-not $value) {
        Write-Host "Error: Value cannot be empty" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Storing $Key in Vault..." -ForegroundColor Yellow
    Write-VaultSecret -Key $Key -Value $value
    Write-Host "✓ Stored successfully" -ForegroundColor Green
    Write-Host ""
    
    return $value
}

# Main function
Check-Vault

Write-Host "Checking secrets..." -ForegroundColor Cyan
Write-Host ""

# Prompt for IBM Cloud API Key
Write-Host "1. IBM Cloud API Key" -ForegroundColor Yellow
Write-Host "   Used for: Terraform IBM Cloud authentication" -ForegroundColor Gray
$IBM_API_KEY = Prompt-Secret -Key "ibmcloud_api_key" -PromptText "Enter IBM Cloud API Key" -IsPassword $false
Write-Host ""

# Prompt for Admin Email
Write-Host "2. IBM Verify Admin Email" -ForegroundColor Yellow
Write-Host "   Used for: Playwright UI automation" -ForegroundColor Gray
$ADMIN_EMAIL = Prompt-Secret -Key "verify_admin_user" -PromptText "Enter IBM Verify Admin Email" -IsPassword $false
Write-Host ""

# Prompt for Admin Password
Write-Host "3. IBM Verify Admin Password" -ForegroundColor Yellow
Write-Host "   Used for: Playwright UI automation" -ForegroundColor Gray
$ADMIN_PASS = Prompt-Secret -Key "verify_admin_pass" -PromptText "Enter IBM Verify Admin Password" -IsPassword $true
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "All secrets are stored in Vault!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To retrieve secrets:" -ForegroundColor Yellow
Write-Host "  vault kv get $VAULT_MOUNT/$VAULT_PATH" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  .\scripts\update_env.ps1" -ForegroundColor White
Write-Host ""

