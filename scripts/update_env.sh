#!/bin/bash
# Script to apply Terraform and update .env file

set -e

echo "=========================================="
echo "IBM Verify Terraform Deployment"
echo "=========================================="
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

# Plan the deployment
echo ""
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply the configuration
echo ""
echo "Applying Terraform configuration..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "The .env file has been created/updated with your IBM Verify credentials."
echo ""
echo "To view the outputs:"
echo "  terraform output"
echo ""
echo "To view sensitive outputs:"
echo "  terraform output verify_tenant_id"
echo ""

