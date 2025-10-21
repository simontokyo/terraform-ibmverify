# Quick Start Guide

Deploy IBM Verify in 5 minutes and get the hostname written to your `.env` file automatically.

**Important:** IBM Verify is only available in the `eu-de` (Frankfurt) region.

**日本語版**: [QUICKSTART.ja.md](QUICKSTART.ja.md)

## 1. Get IBM Cloud API Key

1. Go to https://cloud.ibm.com/iam/apikeys
2. Click "Create an IBM Cloud API key"
3. Give it a name (e.g., "terraform-verify")
4. Copy the API key (you won't be able to see it again!)

## 2. Configure Terraform

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the file and add your required values
# On Windows, use: notepad terraform.tfvars
# On Mac/Linux, use: nano terraform.tfvars
```

**Required values (4):**
```hcl
ibmcloud_api_key = "your-api-key"
resource_group   = "Default"           # Or your resource group name
instance_name    = "my-verify-instance"
hostname         = "mycompany"         # Creates https://mycompany.verify.ibm.com
```

**Optional values (has defaults):**
- `prefix` - Prefix for new resource group (if `resource_group = null`)
- `region` - Defaults to `eu-de` (only supported region)
- `resource_tags` - Tags for resource organization
- `access_tags` - Access tags for fine-grained access control

## 3. Deploy

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\update_env.ps1
```

### Mac/Linux
```bash
chmod +x scripts/update_env.sh
./scripts/update_env.sh
```

## 4. Use Your Credentials

The `.env` file now contains your IBM Verify credentials:
- Hostname
- OAuth URL
- Management URL
- Client ID and Secret
- Tenant ID

You can load these in your application!

## What's Next?

### Access Your Dashboard

Open the dashboard URL (shown in outputs):
```
https://<your-hostname>.verify.ibm.com/ui/admin/
```

### Enable REST API Automation (Optional)

To use REST APIs:
1. Visit the API Access page (URL is in your `.env` file as `IBM_VERIFY_API_ACCESS_URL`)
2. Create an API client and save the credentials
3. Add the credentials to your `.env` file


### Learn More

- [README.md](README.md) - Complete documentation
- [IBM Verify Documentation](https://www.ibm.com/docs/en/security-verify) - Official documentation
- Run `terraform output` to see all available values

## Need to Clean Up?

### Windows
```powershell
.\scripts\destroy.ps1
```

### Mac/Linux
```bash
./scripts/destroy.sh
```

---

**Note:** Keep your `terraform.tfvars` and `.env` files secure. Never commit them to version control!

