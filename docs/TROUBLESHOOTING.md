# Troubleshooting Guide

Common issues and solutions when working with this Terraform Cloud template.

## Table of Contents

1. [Setup and Configuration](#setup-and-configuration)
2. [Terraform Cloud Authentication](#terraform-cloud-authentication)
3. [AWS Credentials](#aws-credentials)
4. [State Management](#state-management)
5. [Remote State Access](#remote-state-access)
6. [Backend Initialization](#backend-initialization)
7. [Module Errors](#module-errors)
8. [CI/CD Issues](#cicd-issues)
9. [Network and Connectivity](#network-and-connectivity)
10. [Getting Help](#getting-help)

## Setup and Configuration

### Error: "command not found: terraform"

**Cause**: Terraform is not installed or not in PATH.

**Solution**:
```bash
# macOS
brew install terraform

# Verify installation
terraform version
```

### Error: "Python module not found"

**Cause**: Python dependencies not installed.

**Solution**:
```bash
cd scripts
python3 -m venv venv
source venv/bin/activate  # or venv/Scripts/activate on Windows
pip install -r requirements.txt
```

### Setup script fails on Windows

**Cause**: Line ending issues or shell compatibility.

**Solution**:
```bash
# Use Git Bash (recommended) or WSL
# Convert line endings
dos2unix scripts/setup.sh

# Or recreate the script from GitHub
git config core.autocrlf false
git clone <repo>
```

## Terraform Cloud Authentication

### Error: "unauthorized" during terraform init

**Cause**: Terraform CLI not authenticated with Terraform Cloud.

**Solution**:
```bash
# Authenticate interactively
terraform login

# Browser opens, generate token, paste in terminal
# Then retry
terraform init
```

**Manual credentials setup**:
```bash
# Create credentials directory
mkdir -p ~/.terraform.d

# Create credentials file (Windows Git Bash / Linux / macOS)
cat > ~/.terraform.d/credentials.tfrc.json <<'EOF'
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR-TOKEN-HERE"
    }
  }
}
EOF

# Get token from: https://app.terraform.io/app/settings/tokens
```

### Error: "401 Unauthorized"

**Cause**: Invalid or expired Terraform Cloud API token.

**Solution**:
```bash
# Re-authenticate
terraform login

# Or manually update credentials file
# Linux/macOS: ~/.terraform.d/credentials.tfrc.json
# Windows: %APPDATA%/terraform.d/credentials.tfrc.json
```

### Error: "Organization not found"

**Cause**: Incorrect organization name or no access.

**Solution**:
1. Verify organization name in Terraform Cloud UI
2. Check you're a member of the organization
3. Update `backend.tf` with correct name

### Token permissions insufficient

**Cause**: Token doesn't have required permissions.

**Solution**:
- Use **User Token** for full access, or
- Use **Team Token** with appropriate permissions:
  - `Read` for plan
  - `Write` for apply
  - `Admin` for workspace management

## AWS Credentials

### Error: "No valid credential sources found"

**Cause**: AWS credentials not configured.

**Solution Option 1** - Terraform Cloud UI:
```
1. Go to workspace
2. Variables → Add variable
3. Add as Environment Variables:
   - AWS_ACCESS_KEY_ID (mark sensitive)
   - AWS_SECRET_ACCESS_KEY (mark sensitive)
   - AWS_DEFAULT_REGION
```

**Solution Option 2** - Local credentials (for testing):
```bash
aws configure
# Enter credentials when prompted
```

### Error: "UnauthorizedOperation"

**Cause**: AWS credentials lack required permissions.

**Solution**:
1. Check IAM policy attached to user/role
2. Add required permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:*",
      "vpc:*",
      "iam:*",
      "s3:*"
    ],
    "Resource": "*"
  }]
}
```

### Error: "ExpiredToken"

**Cause**: Temporary credentials expired.

**Solution**:
- Refresh credentials if using assumed role
- Use long-term credentials for Terraform Cloud
- Or configure OIDC (see SETUP_GUIDE.md)

## State Management

### Error: "State lock failed"

**Cause**: Another operation is in progress or lock wasn't released.

**Solution**:
```bash
# Check who has the lock in Terraform Cloud UI
# If legitimate: wait for operation to complete
# If stuck:
terraform force-unlock <LOCK_ID>  # Use with caution!
```

### Error: "State file version too new"

**Cause**: State was created with newer Terraform version.

**Solution**:
```bash
# Upgrade Terraform
brew upgrade terraform

# Or specify required version
terraform version
```

### Lost state file

**Cause**: Deleted workspace or local state file lost.

**Solution for Terraform Cloud**:
1. State is backed up in Terraform Cloud
2. Go to Workspace → States → View previous versions
3. Can restore or download previous state

**Prevention**: Never manually delete workspaces

## Remote State Access

### Error: "No stored state found for workspace"

**Cause**: Workspace hasn't been applied yet or doesn't exist.

**Solution**:
```bash
# 1. Verify workspace name
data "terraform_remote_state" "infra" {
  config = {
    workspaces = {
      name = "infrastructure-dev"  # Check this is correct
    }
  }
}

# 2. Check workspace exists in Terraform Cloud
# 3. Apply shared infrastructure first
cd environments/dev
terraform apply
```

### Error: "Access denied to workspace"

**Cause**: Remote state sharing not enabled.

**Solution**:
1. In shared workspace: Settings → General Settings
2. Under "Remote state sharing": Select "Share with specific workspaces"
3. Add your workspace name
4. Save settings

### Error: "Output not found in remote state"

**Cause**: Output doesn't exist or hasn't been applied.

**Solution**:
```bash
# 1. Check available outputs
cd environments/dev
terraform output

# 2. Add missing output to outputs.tf
output "vpc_id" {
  value = module.vpc.vpc_id
}

# 3. Apply changes
terraform apply

# 4. Verify from consuming workspace
terraform refresh
```

## Backend Initialization

### Error: "Backend configuration changed"

**Cause**: Modified backend configuration after initialization.

**Solution**:
```bash
# Reinitialize with migration
terraform init -migrate-state

# Or reconfigure
terraform init -reconfigure
```

### Error: "Workspace already exists"

**Cause**: Workspace name conflict.

**Solution**:
1. Use different workspace name, or
2. Delete old workspace in Terraform Cloud (careful!), or
3. Reuse existing workspace

### Error: "Failed to get existing workspaces"

**Cause**: Network connectivity or authentication issue.

**Solution**:
```bash
# 1. Check internet connection
# 2. Verify Terraform Cloud is accessible
curl https://app.terraform.io

# 3. Check credentials
cat ~/.terraform.d/credentials.tfrc.json

# 4. Retry initialization
terraform init
```

## Module Errors

### Error: "Unreadable module directory" (Remote Execution)

**Error Message**:
```
Error: Unreadable module directory
Unable to evaluate directory symlink: lstat ../../modules: no such file or directory
The directory could not be read for module "vpc" at main.tf:24.
```

**Cause**: When using Terraform Cloud remote execution with `working-directory` set, only that specific directory is uploaded, not the parent directories containing modules.

**Solution**:

 **For GitHub Actions** (already fixed in this template):
The workflows use `terraform -chdir=environments/dev` instead of setting `working-directory`. This ensures the entire repository is uploaded to Terraform Cloud.

```yaml
#  Correct - uploads entire repo
- run: terraform -chdir=environments/dev init

#  Wrong - only uploads environments/dev
working-directory: environments/dev
- run: terraform init
```

 **For Local CLI Usage**:
Run from the project root using `-chdir`:
```bash
# From project root
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

 **Alternative: Use Local Execution Mode**:
In Terraform Cloud workspace settings:
1. Settings → General → Execution Mode
2. Change from "Remote" to "Local"
3. This runs Terraform on your machine, giving it access to local files

**Why this happens**: Terraform Cloud's remote execution only receives files from the working directory and below. Using `-chdir` from the root ensures both `environments/` and `modules/` directories are accessible.

---

### Error: "Module not found"

**Cause**: Incorrect module source path.

**Solution**:
```hcl
#  Wrong
module "vpc" {
  source = "../modules/vpc"  # Wrong relative path
}

#  Correct (from environment directory)
module "vpc" {
  source = "../../modules/vpc"
}
```

### Error: "Required variable not set"

**Cause**: Missing required variable.

**Solution**:
```bash
# Option 1: Set in terraform.tfvars
vpc_cidr = "10.0.0.0/16"

# Option 2: Pass via command line
terraform apply -var="vpc_cidr=10.0.0.0/16"

# Option 3: Set default in variables.tf
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
```

### Error: "Invalid for_each argument"

**Cause**: for_each requires a map or set, got null or list.

**Solution**:
```hcl
#  Wrong: null value
resource "aws_subnet" "private" {
  for_each = var.subnet_cidrs  # If null, this fails
}

#  Correct: Handle null
resource "aws_subnet" "private" {
  for_each = var.subnet_cidrs != null ? var.subnet_cidrs : []
}
```

## CI/CD Issues

### GitHub Actions: "Error: Terraform Cloud token not found"

**Cause**: `TF_API_TOKEN` secret not configured.

**Solution**:
1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. New repository secret:
   - Name: `TF_API_TOKEN`
   - Value: [Your Terraform Cloud token]

### GitHub Actions: Workflow not triggering

**Cause**: Path filters or branch restrictions.

**Solution**:
```yaml
# Check workflow trigger paths
on:
  push:
    branches:
      - main
    paths:
      - 'environments/**'  # Only triggers on these paths
      - 'modules/**'
```

### CI/CD: Plan succeeds but apply fails

**Cause**: State changed between plan and apply.

**Solution**:
- This is normal Terraform behavior
- Review the new plan
- Re-apply if changes are acceptable
- Consider state locking enforcement

## VCS-Driven Workflow Issues

### VCS Integration: Runs not triggering automatically

**Cause**: VCS not properly connected or working directory mismatch.

**Solution**:
```bash
# Check workspace settings:
1. Settings → Version Control
2. Verify repository connected
3. Check working directory matches pushed files
4. Verify branch is correct (usually "main")

# Example:
Working Directory: environments/dev
Push must affect: environments/dev/** or modules/**
```

### VCS Integration: "OAuth token invalid"

**Cause**: VCS connection expired or revoked.

**Solution**:
1. Organization Settings → Version Control → Providers
2. Find your VCS provider
3. Click "Reconnect"
4. Reauthorize OAuth access

### VCS Integration: Multiple workspaces triggering on same push

**Cause**: Overlapping trigger patterns or working directories.

**Solution**:
```
Configure specific trigger patterns per workspace:

Workspace: infrastructure-dev
Trigger patterns:
- environments/dev/**
- modules/**

Workspace: infrastructure-prod
Trigger patterns:
- environments/prod/**
- modules/**
```

### VCS Integration: Speculative plans not showing in PRs

**Cause**: PR comments not enabled or permissions issue.

**Solution**:
1. Workspace Settings → VCS
2. Enable "Automatic speculative plans"
3. Verify GitHub App has PR comment permissions
4. Check PR is from same repository (not fork)

**See**: [VCS Integration Guide](VCS_INTEGRATION.md#troubleshooting) for detailed troubleshooting

## Network and Connectivity

### Error: "Error creating VPC: InvalidParameterValue"

**Cause**: Invalid CIDR block or overlapping ranges.

**Solution**:
```hcl
# Ensure CIDR blocks don't overlap
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]  # Inside VPC CIDR
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]  # Inside VPC CIDR
```

### Error: "InvalidAvailabilityZone"

**Cause**: Specified AZ doesn't exist in region.

**Solution**:
```bash
# Check available AZs
aws ec2 describe-availability-zones --region us-east-1

# Update variables
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### NAT Gateway creation fails

**Cause**: No Elastic IP or Internet Gateway.

**Solution**:
Ensure resources are created in correct order (handled by dependencies in module):
1. VPC
2. Internet Gateway
3. Elastic IP
4. NAT Gateway

### Timeout creating resources

**Cause**: AWS service issues or large resource creation.

**Solution**:
```bash
# Increase timeout (if needed)
resource "aws_nat_gateway" "main" {
  # ...
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
```

## Common Error Messages

### "Error: local-exec provisioner error"

**Cause**: Script execution failed.

**Solution**:
```hcl
# Check script syntax
# Ensure script is executable
# Use absolute paths
# Check script output in Terraform logs
```

### "Error: Provider configuration not present"

**Cause**: Provider not configured or incorrect version.

**Solution**:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### "Error: Cycle in dependencies"

**Cause**: Circular reference between resources.

**Solution**:
- Review resource dependencies
- Remove circular references
- Use `depends_on` explicitly if needed
- Restructure resources

## Performance Issues

### Terraform operations are slow

**Possible causes and solutions**:

1. **Large state file**
   - Break into multiple workspaces
   - Use `-target` for specific resources

2. **Many resources**
   - Use `-parallelism=20` to increase concurrent operations
   - Consider module boundaries

3. **Network latency**
   - Use Terraform Cloud remote execution
   - Check internet connection speed

### Plan takes too long

**Solution**:
```bash
# Use target flag for specific resources
terraform plan -target=module.vpc

# Or refresh state less frequently
terraform plan -refresh=false
```

## Cost Issues

### Unexpected AWS costs

**Check these resources**:
- NAT Gateways (~$32/month each)
- EC2 instances running 24/7
- Data transfer charges
- EBS volumes

**Solution**:
```hcl
# Dev: Use single NAT Gateway
single_nat_gateway = true  # Saves ~$66/month

# Use smaller instance types for dev
instance_type = "t3.micro"  # vs t3.large

# Enable cost estimation in Terraform Cloud
# Review before applying
```

## Debug Mode

### Enable detailed logging

```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run command
terraform plan

# Review logs
cat terraform.log
```

### Terraform Cloud logs

View detailed logs in Terraform Cloud:
1. Go to workspace
2. Select run
3. View plan/apply output
4. Download logs if needed

## Getting Help

### 1. Check Documentation

- [Terraform Cloud Docs](https://developer.hashicorp.com/terraform/cloud-docs)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- This repository's `docs/` directory

### 2. Validate Configuration

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Plan with verbose output
terraform plan -no-color | tee plan.txt
```

### 3. Community Resources

- [Terraform Forum](https://discuss.hashicorp.com/c/terraform-core)
- [Stack Overflow - Terraform Tag](https://stackoverflow.com/questions/tagged/terraform)
- [AWS Forums](https://repost.aws/)

### 4. Enterprise Support

- Terraform Cloud Support (paid tiers)
- AWS Support
- HashiCorp Professional Services

## Preventive Measures

### Best practices to avoid issues:

1.  Always run `terraform plan` before `apply`
2.  Use version control for all Terraform code
3.  Never edit state files manually
4.  Keep Terraform and providers updated
5.  Use consistent formatting (`terraform fmt`)
6.  Review changes in pull requests
7.  Test in dev before applying to prod
8.  Keep sensitive data out of version control
9.  Document custom configurations
10.  Regular backups (Terraform Cloud does this automatically)

## Still Stuck?

If you're still experiencing issues:

1. Document the exact error message
2. Include relevant configuration (sanitize secrets)
3. Note what you've already tried
4. Check if issue is reproducible
5. Open an issue on the repository

Remember: The Terraform Cloud UI provides excellent debugging information. Always check the run details for specific error messages and context.
