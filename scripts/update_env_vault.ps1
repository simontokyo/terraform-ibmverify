# Script to apply Terraform with secrets from Vault and update .env file
# PowerShell version for Windows

$ErrorActionPreference = "Stop"

$VAULT_ADDR = if ($env:VAULT_ADDR) { $env:VAULT_ADDR } else { "http://127.0.0.1:8200" }
$VAULT_TOKEN = if ($env:VAULT_TOKEN) { $env:VAULT_TOKEN } else { "root" }
$VAULT_MOUNT = "secret"
$VAULT_PATH = "ibm"

# Export for vault CLI
$env:VAULT_ADDR = $VAULT_ADDR
$env:VAULT_TOKEN = $VAULT_TOKEN

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "IBM Verify Terraform Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Vault is accessible
if (-not (Get-Command vault -ErrorAction SilentlyContinue)) {
    Write-Host "Error: vault CLI not found!" -ForegroundColor Red
    Write-Host "Please run: .\scripts\vault_setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

try {
    vault status | Out-Null
    Write-Host "✓ Connected to Vault" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot connect to Vault at $VAULT_ADDR" -ForegroundColor Red
    Write-Host "Please run: .\scripts\vault_setup.ps1 first" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Retrieve secrets from Vault
Write-Host "Retrieving secrets from Vault..." -ForegroundColor Yellow
try {
    $IBM_API_KEY = vault kv get -field=ibmcloud_api_key "$VAULT_MOUNT/$VAULT_PATH"
    $ADMIN_EMAIL = vault kv get -field=verify_admin_user "$VAULT_MOUNT/$VAULT_PATH"
    $ADMIN_PASS = vault kv get -field=verify_admin_pass "$VAULT_MOUNT/$VAULT_PATH"
} catch {
    Write-Host "Error: Required secrets not found in Vault" -ForegroundColor Red
    Write-Host "Please run: .\scripts\vault_setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

if (-not $IBM_API_KEY -or -not $ADMIN_EMAIL -or -not $ADMIN_PASS) {
    Write-Host "Error: Required secrets not found in Vault" -ForegroundColor Red
    Write-Host "Please run: .\scripts\vault_setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Retrieved secrets successfully" -ForegroundColor Green
Write-Host ""

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "Error: terraform.tfvars not found!" -ForegroundColor Red
    Write-Host "Please copy terraform.tfvars.example to terraform.tfvars and configure it." -ForegroundColor Yellow
    exit 1
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Green
terraform init

# Validate configuration
Write-Host ""
Write-Host "Validating Terraform configuration..." -ForegroundColor Green
terraform validate

# Plan the deployment with API key from Vault
Write-Host ""
Write-Host "Planning deployment..." -ForegroundColor Green
terraform plan `
    -var="ibmcloud_api_key=$IBM_API_KEY" `
    -out=tfplan

# Ask for confirmation
Write-Host ""
$confirm = Read-Host "Do you want to apply this plan? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue
    exit 0
}

# Apply the configuration
Write-Host ""
Write-Host "Applying Terraform configuration..." -ForegroundColor Green
terraform apply `
    -var="ibmcloud_api_key=$IBM_API_KEY" `
    tfplan

# Clean up plan file
Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue

# Update .env with admin credentials from Vault
if (Test-Path ".env") {
    Write-Host ""
    Write-Host "Updating .env with admin credentials from Vault..." -ForegroundColor Yellow
    
    $envContent = Get-Content ".env" -Raw
    
    # Update or add admin email
    if ($envContent -match "IBM_VERIFY_ADMIN_EMAIL=") {
        $envContent = $envContent -replace "IBM_VERIFY_ADMIN_EMAIL=.*", "IBM_VERIFY_ADMIN_EMAIL=$ADMIN_EMAIL"
    } else {
        $envContent = $envContent -replace "(# IBM_VERIFY_ADMIN_EMAIL=.*)", "`$1`nIBM_VERIFY_ADMIN_EMAIL=$ADMIN_EMAIL"
    }
    
    # Update or add admin password
    if ($envContent -match "IBM_VERIFY_ADMIN_PASSWORD=") {
        $envContent = $envContent -replace "IBM_VERIFY_ADMIN_PASSWORD=.*", "IBM_VERIFY_ADMIN_PASSWORD=$ADMIN_PASS"
    } else {
        $envContent = $envContent -replace "(# IBM_VERIFY_ADMIN_PASSWORD=.*)", "`$1`nIBM_VERIFY_ADMIN_PASSWORD=$ADMIN_PASS"
    }
    
    Set-Content ".env" -Value $envContent -NoNewline
    Write-Host "✓ Admin credentials added to .env" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The .env file has been created/updated with your IBM Verify credentials." -ForegroundColor Green
Write-Host "Admin credentials were retrieved from Vault." -ForegroundColor Cyan
Write-Host ""
Write-Host "To view the outputs:" -ForegroundColor Yellow
Write-Host "  terraform output" -ForegroundColor White
Write-Host ""
Write-Host "To view sensitive outputs:" -ForegroundColor Yellow
Write-Host "  terraform output tenant_id" -ForegroundColor White
Write-Host ""

