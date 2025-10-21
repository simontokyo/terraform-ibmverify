# HashiCorp Vault Integration

This directory contains scripts for securely managing IBM Verify secrets using HashiCorp Vault instead of storing them in `.env` or `terraform.tfvars` files.

## Critical Secrets Managed

The following three secrets are stored in Vault:

1. **`ibmcloud_api_key`** - IBM Cloud API key for Terraform authentication
2. **`verify_admin_user`** - IBM Verify admin email for Playwright automation  
3. **`verify_admin_pass`** - IBM Verify admin password for Playwright automation

## Quick Start

### 1. Start Vault (Docker)

```bash
docker run --name vault-dev -d -p 8200:8200 -e "VAULT_DEV_ROOT_TOKEN_ID=root" hashicorp/vault
```

**Environment Variables:**
- `VAULT_ADDR`: Vault server address (default: `http://127.0.0.1:8200`)
- `VAULT_TOKEN`: Vault authentication token (default: `root`)

### 2. Initialize Secrets

**Linux/Mac:**
```bash
chmod +x scripts/vault_setup.sh
./scripts/vault_setup.sh
```

**Windows:**
```powershell
.\scripts\vault_setup.ps1
```

This script will:
- Check Vault connectivity
- Prompt for secrets if they don't exist
- Store secrets in Vault at `secret/ibm`
- Reuse existing secrets on subsequent runs

### 3. Deploy with Vault

**Linux/Mac:**
```bash
chmod +x scripts/update_env_vault.sh
./scripts/update_env_vault.sh
```

**Windows:**
```powershell
.\scripts\update_env_vault.ps1
```

This script will:
- Retrieve secrets from Vault
- Run Terraform with secrets from Vault (not from `.tfvars`)
- Update `.env` file with admin credentials from Vault
- Deploy IBM Verify instance

## Vault Storage Structure

```
secret/
└── ibm/
    ├── ibmcloud_api_key      # IBM Cloud API key
    ├── verify_admin_user     # Admin email
    └── verify_admin_pass     # Admin password
```

## Manual Vault Operations

### View all secrets

```bash
vault kv get secret/ibm
```

### View specific secret

```bash
vault kv get -field=ibmcloud_api_key secret/ibm
vault kv get -field=verify_admin_user secret/ibm
vault kv get -field=verify_admin_pass secret/ibm
```

### Update a secret

```bash
vault kv put secret/ibm \
  ibmcloud_api_key="your-new-api-key" \
  verify_admin_user="your-email@ibm.com" \
  verify_admin_pass="your-new-password"
```

### Delete secrets

```bash
vault kv delete secret/ibm
```

## Security Benefits

### Before (Without Vault)
- ❌ Secrets in plain text in `terraform.tfvars`
- ❌ Secrets in plain text in `.env`
- ❌ Risk of committing secrets to Git
- ❌ No audit trail

### After (With Vault)
- ✅ Secrets encrypted at rest in Vault
- ✅ Centralized secret management
- ✅ No secrets in source code
- ✅ Audit trail of secret access
- ✅ Easy secret rotation

## Workflow Comparison

### Traditional Workflow
```
1. Edit terraform.tfvars (add API key)
2. Run terraform apply
3. Edit .env (add admin credentials)
4. Run playwright tests
```

### Vault Workflow
```
1. Run vault_setup.sh (once - stores secrets in Vault)
2. Run update_env_vault.sh (retrieves from Vault, deploys)
3. Run playwright tests (reads from .env updated by script)
```

## Production Deployment

For production, use a proper Vault installation instead of dev mode:

```bash
# Don't use dev mode in production!
# Use HashiCorp Vault Cloud or self-hosted production Vault
# with proper authentication (AppRole, JWT, etc.)
```

### Production Best Practices

1. **Use AppRole or JWT authentication** instead of root token
2. **Enable audit logging** to track secret access
3. **Use Vault policies** to restrict access by service
4. **Rotate secrets regularly** using Vault's rotation features
5. **Use Vault's dynamic secrets** where possible
6. **Enable TLS** for Vault communication

## Troubleshooting

### Vault connection error

```
Error: Cannot connect to Vault at http://127.0.0.1:8200
```

**Solution:** Make sure Vault is running:
```bash
docker ps | grep vault
# If not running:
docker start vault-dev
```

### Token authentication error

```
Error: permission denied
```

**Solution:** Set the correct token:
```bash
export VAULT_TOKEN=root
```

### Secrets not found

```
Error: Required secrets not found in Vault
```

**Solution:** Run the setup script first:
```bash
./scripts/vault_setup.sh
```

## Files

- `vault_setup.sh` / `vault_setup.ps1` - Initialize and manage secrets in Vault
- `update_env_vault.sh` / `update_env_vault.ps1` - Deploy with secrets from Vault
- `VAULT_README.md` - This file

## Integration with Existing Scripts

The original `update_env.sh` and `update_env.ps1` scripts still work for non-Vault workflows. Use `update_env_vault.*` scripts when you want to use Vault for secret management.

