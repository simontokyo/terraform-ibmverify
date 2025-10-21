#!/bin/bash
# Script to destroy IBM Verify infrastructure

set -e

echo "=========================================="
echo "IBM Verify Terraform Destroy"
echo "=========================================="
echo ""

# Warning message
echo "WARNING: This will destroy your IBM Verify instance and all associated resources!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Destroy cancelled."
    exit 0
fi

echo ""
read -p "Type 'destroy' to confirm: " confirm2
if [ "$confirm2" != "destroy" ]; then
    echo "Destroy cancelled."
    exit 0
fi

# Destroy the infrastructure
echo ""
echo "Destroying IBM Verify infrastructure..."
terraform destroy -auto-approve

echo ""
echo "=========================================="
echo "Destroy Complete!"
echo "=========================================="
echo ""

