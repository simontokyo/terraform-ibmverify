# Script to apply Terraform and update .env file
# PowerShell version for Windows

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "IBM Verify Terraform Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
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

# Plan the deployment
Write-Host ""
Write-Host "Planning deployment..." -ForegroundColor Green
terraform plan -out=tfplan

# Ask for confirmation
Write-Host ""
$confirm = Read-Host "Do you want to apply this plan? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

# Apply the configuration
Write-Host ""
Write-Host "Applying Terraform configuration..." -ForegroundColor Green
terraform apply tfplan

# Clean up plan file
Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The .env file has been created/updated with your IBM Verify credentials." -ForegroundColor Green
Write-Host ""
Write-Host "To view the outputs:" -ForegroundColor Yellow
Write-Host "  terraform output" -ForegroundColor White
Write-Host ""
Write-Host "To view sensitive outputs:" -ForegroundColor Yellow
Write-Host "  terraform output verify_tenant_id" -ForegroundColor White
Write-Host ""

