#!/bin/bash
# HashiCorp Vault integration for IBM Verify secrets
# This script manages secrets in Vault and retrieves them for Terraform

set -e

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
VAULT_MOUNT="secret"
VAULT_PATH="ibm"

# Export for vault CLI
export VAULT_ADDR
export VAULT_TOKEN

echo "=========================================="
echo "IBM Verify - Vault Secret Management"
echo "=========================================="
echo ""
echo "Vault Address: $VAULT_ADDR"
echo ""

# Check if Vault is accessible
check_vault() {
    if ! command -v vault &> /dev/null; then
        echo "Error: vault CLI not found!"
        echo "Install from: https://www.vaultproject.io/downloads"
        echo ""
        echo "Or use Docker:"
        echo "  docker run --name vault-dev -d -p 8200:8200 -e \"VAULT_DEV_ROOT_TOKEN_ID=root\" hashicorp/vault"
        exit 1
    fi

    if ! vault status &> /dev/null; then
        echo "Error: Cannot connect to Vault at $VAULT_ADDR"
        echo ""
        echo "Make sure Vault is running:"
        echo "  docker run --name vault-dev -d -p 8200:8200 -e \"VAULT_DEV_ROOT_TOKEN_ID=root\" hashicorp/vault"
        exit 1
    fi

    echo "✓ Connected to Vault successfully"
    echo ""
}

# Read secret from Vault
read_secret() {
    local key=$1
    vault kv get -field="$key" "$VAULT_MOUNT/$VAULT_PATH" 2>/dev/null || echo ""
}

# Write secret to Vault
write_secret() {
    local key=$1
    local value=$2
    
    # Read existing secrets
    local existing=$(vault kv get -format=json "$VAULT_MOUNT/$VAULT_PATH" 2>/dev/null || echo "{}")
    
    # Update the specific key
    vault kv put "$VAULT_MOUNT/$VAULT_PATH" \
        ibmcloud_api_key="$(echo "$existing" | jq -r '.data.data.ibmcloud_api_key // ""')" \
        verify_admin_user="$(echo "$existing" | jq -r '.data.data.verify_admin_user // ""')" \
        verify_admin_pass="$(echo "$existing" | jq -r '.data.data.verify_admin_pass // ""')" \
        "$key"="$value" > /dev/null
}

# Prompt for secret if not in Vault
prompt_secret() {
    local key=$1
    local prompt_text=$2
    local is_password=$3
    
    local existing=$(read_secret "$key")
    
    if [ -n "$existing" ]; then
        echo "✓ Found $key in Vault"
        echo "$existing"
        return
    fi
    
    echo "⚠ $key not found in Vault"
    echo ""
    
    if [ "$is_password" = "true" ]; then
        read -sp "$prompt_text: " value
        echo ""
    else
        read -p "$prompt_text: " value
    fi
    
    if [ -z "$value" ]; then
        echo "Error: Value cannot be empty"
        exit 1
    fi
    
    echo "Storing $key in Vault..."
    write_secret "$key" "$value"
    echo "✓ Stored successfully"
    echo ""
    echo "$value"
}

# Main function
main() {
    check_vault
    
    echo "Checking secrets..."
    echo ""
    
    # Prompt for IBM Cloud API Key
    echo "1. IBM Cloud API Key"
    echo "   Used for: Terraform IBM Cloud authentication"
    IBM_API_KEY=$(prompt_secret "ibmcloud_api_key" "Enter IBM Cloud API Key" false)
    echo ""
    
    # Prompt for Admin Email
    echo "2. IBM Verify Admin Email"
    echo "   Used for: Playwright UI automation"
    ADMIN_EMAIL=$(prompt_secret "verify_admin_user" "Enter IBM Verify Admin Email" false)
    echo ""
    
    # Prompt for Admin Password
    echo "3. IBM Verify Admin Password"
    echo "   Used for: Playwright UI automation"
    ADMIN_PASS=$(prompt_secret "verify_admin_pass" "Enter IBM Verify Admin Password" true)
    echo ""
    
    echo "=========================================="
    echo "All secrets are stored in Vault!"
    echo "=========================================="
    echo ""
    echo "To retrieve secrets:"
    echo "  vault kv get $VAULT_MOUNT/$VAULT_PATH"
    echo ""
    echo "Next steps:"
    echo "  ./scripts/update_env.sh"
    echo ""
}

main

