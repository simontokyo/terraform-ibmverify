# Getting Started with IBM Verify Terraform

This guide will help you deploy IBM Verify in under 10 minutes.

## ✅ Prerequisites

- [x] IBM Cloud account
- [x] Terraform 1.0+ installed
- [x] IBM Cloud CLI (optional, for getting resource group ID)

## 🚀 Quick Start (3 Steps)

### Step 1: Get Required Information

#### 1.1 Get IBM Cloud API Key
1. Go to https://cloud.ibm.com/iam/apikeys
2. Click "Create an IBM Cloud API key"
3. Copy and save the key securely

#### 1.2 Get Resource Group ID
```bash
# Option A: Using IBM Cloud CLI
ibmcloud login
ibmcloud resource groups

# Option B: From Console
# Visit: https://cloud.ibm.com/account/resource-groups
# Copy the ID (not the name)
```

### Step 2: Configure

```bash
# Clone or navigate to this directory
cd verify2

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Windows: notepad terraform.tfvars
# Mac/Linux: nano terraform.tfvars
```

**Fill in these 4 required values:**
```hcl
ibmcloud_api_key  = "your-api-key-here"
resource_group_id = "your-resource-group-id"
instance_name     = "my-verify-instance"
hostname          = "mycompany"  # Your subdomain: https://mycompany.verify.ibm.com
# region defaults to "eu-de" (the only supported region)
```

### Step 3: Deploy

#### Windows
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\update_env.ps1
```

#### Mac/Linux
```bash
chmod +x scripts/update_env.sh
./scripts/update_env.sh
```

#### Or Manually
```bash
terraform init
terraform plan
terraform apply
```

## ✨ What You Get

After deployment, you'll have:

1. **IBM Verify Instance** running in eu-de region
2. **Service Credentials** with Manager role
3. **.env File** with all configuration:
   ```env
   IBM_VERIFY_HOSTNAME=mycompany.verify.ibm.com
   IBM_VERIFY_DASHBOARD_URL=https://mycompany.verify.ibm.com/ui/admin/
   IBM_VERIFY_ACCOUNT_URL=https://mycompany.verify.ibm.com
   IBM_VERIFY_OAUTH_URL=...
   IBM_VERIFY_MANAGEMENT_URL=...
   IBM_VERIFY_TENANT_ID=...
   IBM_VERIFY_CLIENT_ID=...
   IBM_VERIFY_CLIENT_SECRET=...
   IBM_VERIFY_INSTANCE_ID=...
   ```

## 📖 Documentation

- **[README.md](README.md)** - Complete documentation
- **[PARAMETERS.md](PARAMETERS.md)** - All parameters explained
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference guide
- **[README.ja.md](README.ja.md)** - 日本語版ドキュメント

## 🔍 Verify Deployment

```bash
# View all outputs
terraform output

# View specific output
terraform output hostname

# Check the .env file
cat .env
```

## 🧹 Clean Up

When you're done:

```bash
# Windows
.\scripts\destroy.ps1

# Mac/Linux
./scripts/destroy.sh

# Or manually
terraform destroy
```

## ❓ Common Issues

### "Invalid region"
**Fix:** IBM Verify only works in `eu-de` region. Don't change this value.

### "Resource group not found"
**Fix:** Make sure you're using the resource group **ID** (not name).
```bash
ibmcloud resource groups  # Get the ID
```

### "Unauthorized"
**Fix:** Your API key needs proper permissions:
- Minimum: Viewer on resource group
- Recommended: Editor on resource group


### "Invalid hostname"
**Fix:** Hostname must contain only lowercase letters, numbers, and hyphens. Examples:
- ✅ `mycompany`, `acme-corp`, `test-01`
- ❌ `MyCompany`, `-company`, `my_company`

## 🔐 Security Reminders

- ❌ Never commit `terraform.tfvars` to git
- ❌ Never commit `.env` to git
- ❌ Never commit `terraform.tfstate` to git
- ✅ Keep API keys secure
- ✅ Rotate API keys regularly
- ✅ Use resource tags for organization

## 📊 Parameter Summary

### Mandatory (Must Provide)
```hcl
ibmcloud_api_key  = "..."      # Your IBM Cloud API key
resource_group_id = "..."      # Resource group ID
instance_name     = "..."      # Instance name
hostname          = "..."      # Your subdomain (e.g., "mycompany")
```

### Optional (Has Defaults)
```hcl
region        = "eu-de"  # Default, only supported region
env_file_path = ".env"   # Change if needed
```

**Note:** Service plan and tags are managed by the module and cannot be customized.

## 🎯 Next Steps

After deployment:

1. **Test the credentials:**
   ```bash
   source .env
   echo $IBM_VERIFY_HOSTNAME
   ```

2. **Access IBM Cloud dashboard:**
   ```bash
   terraform output dashboard_url
   ```

3. **Integrate with your app:**
   - Use the values in `.env`
   - Reference the OAuth URL for authentication
   - Use the Management URL for admin operations

4. **Configure your application:**
   - Set up OIDC/OAuth flows
   - Configure redirect URIs
   - Set up user authentication

## 📚 Additional Resources

- [IBM Verify Documentation](https://www.ibm.com/docs/en/security-verify)
- [IBM Verify](https://www.ibm.com/products/verify)
- [Terraform IBM Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [Official Module](https://registry.terraform.io/modules/terraform-ibm-modules/security-verify/ibm/latest)

## 💡 Pro Tips

1. **Use meaningful names:**
   ```hcl
   instance_name = "prod-myapp-verify"  # Good
   instance_name = "test123"            # Bad
   ```

2. **Use environment variables for API key:**
   ```bash
   export TF_VAR_ibmcloud_api_key="your-key"
   terraform apply
   ```

3. **Keep backups of state:**
   ```bash
   terraform state pull > backup-$(date +%Y%m%d).tfstate
   ```

## 🆘 Need Help?

1. Check [PARAMETERS.md](PARAMETERS.md) for detailed parameter docs
2. Review [README.md](README.md) for full documentation
3. Check IBM Cloud status: https://cloud.ibm.com/status
4. IBM Cloud support: https://cloud.ibm.com/unifiedsupport/supportcenter

---

**Ready to deploy?** Follow the 3 steps above and you'll have IBM Verify running in minutes! 🚀

