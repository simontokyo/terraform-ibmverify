#!/bin/bash
# Script to apply Terraform with secrets from Vault and update .env file

set -e

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
VAULT_MOUNT="secret"
VAULT_PATH="ibm"

# Export for vault CLI
export VAULT_ADDR
export VAULT_TOKEN

echo "=========================================="
echo "IBM Verify Terraform Deployment"
echo "=========================================="
echo ""

# Check if Vault is accessible
if ! command -v vault &> /dev/null; then
    echo "Error: vault CLI not found!"
    echo "Please run: ./scripts/vault_setup.sh first"
    exit 1
fi

if ! vault status &> /dev/null; then
    echo "Error: Cannot connect to Vault at $VAULT_ADDR"
    echo "Please run: ./scripts/vault_setup.sh first"
    exit 1
fi

echo "✓ Connected to Vault"
echo ""

# Retrieve secrets from Vault
echo "Retrieving secrets from Vault..."
IBM_API_KEY=$(vault kv get -field=ibmcloud_api_key "$VAULT_MOUNT/$VAULT_PATH" 2>/dev/null)
ADMIN_EMAIL=$(vault kv get -field=verify_admin_user "$VAULT_MOUNT/$VAULT_PATH" 2>/dev/null)
ADMIN_PASS=$(vault kv get -field=verify_admin_pass "$VAULT_MOUNT/$VAULT_PATH" 2>/dev/null)

if [ -z "$IBM_API_KEY" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASS" ]; then
    echo "Error: Required secrets not found in Vault"
    echo "Please run: ./scripts/vault_setup.sh first"
    exit 1
fi

echo "✓ Retrieved secrets successfully"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found!"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it."
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo ""
echo "Validating Terraform configuration..."
terraform validate

# Plan the deployment with API key from Vault
echo ""
echo "Planning deployment..."
terraform plan \
    -var="ibmcloud_api_key=$IBM_API_KEY" \
    -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply the configuration
echo ""
echo "Applying Terraform configuration..."
terraform apply \
    -var="ibmcloud_api_key=$IBM_API_KEY" \
    tfplan

# Clean up plan file
rm -f tfplan

# Update .env with admin credentials from Vault
if [ -f ".env" ]; then
    echo ""
    echo "Updating .env with admin credentials from Vault..."
    
    # Check if credentials already exist in .env
    if grep -q "^IBM_VERIFY_ADMIN_EMAIL=" .env; then
        sed -i "s|^IBM_VERIFY_ADMIN_EMAIL=.*|IBM_VERIFY_ADMIN_EMAIL=$ADMIN_EMAIL|" .env
    else
        # Add after the admin credentials comment
        sed -i "/^# IBM_VERIFY_ADMIN_EMAIL=/a IBM_VERIFY_ADMIN_EMAIL=$ADMIN_EMAIL" .env
    fi
    
    if grep -q "^IBM_VERIFY_ADMIN_PASSWORD=" .env; then
        sed -i "s|^IBM_VERIFY_ADMIN_PASSWORD=.*|IBM_VERIFY_ADMIN_PASSWORD=$ADMIN_PASS|" .env
    else
        sed -i "/^# IBM_VERIFY_ADMIN_PASSWORD=/a IBM_VERIFY_ADMIN_PASSWORD=$ADMIN_PASS" .env
    fi
    
    echo "✓ Admin credentials added to .env"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "The .env file has been created/updated with your IBM Verify credentials."
echo "Admin credentials were retrieved from Vault."
echo ""
echo "To view the outputs:"
echo "  terraform output"
echo ""
echo "To view sensitive outputs:"
echo "  terraform output tenant_id"
echo ""

