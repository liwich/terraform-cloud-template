# Local Testing Without Terraform Cloud

If you want to test the Terraform configuration locally before setting up Terraform Cloud, follow this guide.

## Quick Local Test

### 1. Create Local Backend Configuration

From the project root:

```bash
# Navigate to environment
cd environments/dev

# Create local backend file
cat > backend.tf <<'EOF'
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  
  required_version = "~> 1.6.0"
}
EOF
```

### 2. Initialize and Test

```bash
# Still in environments/dev/
terraform init
terraform plan
```

## Important Notes

###  Never Commit Local State

The `.gitignore` already prevents this, but ensure you don't commit:
- `terraform.tfstate`
- `terraform.tfstate.backup`
- Local `backend.tf` files

###  Switching to Terraform Cloud Later

When ready to use Terraform Cloud:

```bash
# 1. Run setup script from project root
cd ../../
./scripts/setup.sh

# 2. Remove local state (if you want clean start)
cd environments/dev/
rm terraform.tfstate*
rm -rf .terraform/

# 3. The setup script creates cloud backend.tf
# Re-initialize
terraform init
```

Terraform will ask if you want to migrate state. Say **yes** if you have resources, **no** for clean start.

## Module Path Issues

### Common Error

```
Error: Unreadable module directory
Unable to evaluate directory symlink: lstat ../../modules: no such file or directory
```

### Cause

You're running `terraform` from the wrong directory or the modules don't exist yet.

### Solutions

**Option 1: Run from correct directory**

```bash
# From project root
cd environments/dev
terraform init  # Works because modules/ is at ../../modules/

# Or use -chdir flag from root
terraform -chdir=environments/dev init
```

**Option 2: Verify module path**

```bash
# From environments/dev/, verify modules exist
ls ../../modules/vpc
# Should show: main.tf, variables.tf, outputs.tf, README.md
```

## Directory Structure Reference

```
terraform-cloud-template/       ← Project root
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/
        ├── main.tf             ← References ../../modules/vpc
        ├── variables.tf
        └── backend.tf          ← Created by setup.sh
```

## Testing Workflow

### For Local Development

```bash
# 1. Create local backend
cd environments/dev
cat > backend.tf <<'EOF'
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_version = "~> 1.6.0"
}
EOF

# 2. Initialize
terraform init

# 3. Plan (will prompt for AWS credentials)
terraform plan

# 4. Apply (if you want to create real resources)
terraform apply
```

### For Terraform Cloud Testing

```bash
# 1. Run setup script (from project root)
./scripts/setup.sh

# 2. Navigate to environment
cd environments/dev

# 3. Initialize (connects to Terraform Cloud)
terraform init

# 4. Plan (uses remote execution)
terraform plan

# 5. Apply (uses remote execution)
terraform apply
```

## AWS Credentials for Local Testing

When testing locally, Terraform needs AWS credentials:

### Option 1: Environment Variables

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

terraform plan
```

### Option 2: AWS CLI Profile

```bash
# If you have AWS CLI configured
aws configure

# Then Terraform automatically uses credentials
terraform plan
```

### Option 3: Temporary Credentials

```bash
# For testing without AWS
# Validate configuration only
terraform init
terraform validate

# Plan without AWS credentials will fail at provider initialization
# But validates your configuration syntax
```

## Troubleshooting

### "No configuration files"

```
Error: No configuration files
```

**Cause**: Running from wrong directory

**Solution**: Ensure you're in `environments/dev/` or use `-chdir`

### "Module not installed"

```
Error: Module not installed
Module source has changed
```

**Solution**: Re-run `terraform init`

### "Backend configuration changed"

```
Error: Backend initialization required
```

**Solution**: Run `terraform init -migrate-state` to migrate from local to cloud (or vice versa)

## Best Practices

###  Do

- Test locally with `local` backend first
- Use `.gitignore` to prevent committing state
- Run `terraform plan` before `apply`
- Clean up test resources with `terraform destroy`

###  Don't

- Commit `terraform.tfstate` files
- Use local state for production
- Share local state files between team members
- Mix local and cloud backends without migration

## Clean Up Test Resources

After local testing:

```bash
# Destroy any created resources
terraform destroy

# Remove local state
rm terraform.tfstate*
rm -rf .terraform/

# Remove local backend config
rm backend.tf
```

## Next Steps

Once local testing is complete:

1. **Switch to Terraform Cloud**: Run `./scripts/setup.sh`
2. **Set up CI/CD**: Add `TF_API_TOKEN` to GitHub Secrets
3. **Deploy via automation**: Push changes to trigger workflows

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for full Terraform Cloud setup.
