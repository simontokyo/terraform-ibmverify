# Script to destroy IBM Verify infrastructure
# PowerShell version for Windows

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "IBM Verify Terraform Destroy" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Warning message
Write-Host "WARNING: This will destroy your IBM Verify instance and all associated resources!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Destroy cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
$confirm2 = Read-Host "Type 'destroy' to confirm"
if ($confirm2 -ne "destroy") {
    Write-Host "Destroy cancelled." -ForegroundColor Yellow
    exit 0
}

# Destroy the infrastructure
Write-Host ""
Write-Host "Destroying IBM Verify infrastructure..." -ForegroundColor Green
terraform destroy -auto-approve

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Destroy Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

