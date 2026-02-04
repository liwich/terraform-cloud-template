# Terraform Cloud Setup Guide

This guide provides detailed instructions for setting up and configuring your Terraform Cloud infrastructure template.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Terraform Cloud Setup](#terraform-cloud-setup)
3. [AWS Configuration](#aws-configuration)
4. [Running the Setup Script](#running-the-setup-script)
5. [Manual Setup (Alternative)](#manual-setup-alternative)
6. [VCS Integration](#vcs-integration)
7. [Environment Configuration](#environment-configuration)
8. [Workspace Permissions](#workspace-permissions)

## Prerequisites

### 1. Create Terraform Cloud Account

1. Visit [https://app.terraform.io/signup/account](https://app.terraform.io/signup/account)
2. Sign up for a free account
3. Create an organization (or use an existing one)

### 2. Generate API Token

**User Token** (Recommended for getting started):
1. Go to [https://app.terraform.io/app/settings/tokens](https://app.terraform.io/app/settings/tokens)
2. Click "Create an API token"
3. Give it a description (e.g., "terraform-template-setup")
4. Copy the token (you'll need this for the setup script)

**Team Token** (For production):
- Go to Organization Settings → Teams → Select team → Team API Token
- Use for CI/CD pipelines and team-based access

### 3. Install Required Tools

**Terraform**:
```bash
# macOS
brew install terraform

# Windows (Chocolatey)
choco install terraform

# Linux (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Python 3**:
```bash
# macOS
brew install python3

# Windows
# Download from https://www.python.org/downloads/

# Linux (Ubuntu/Debian)
sudo apt install python3 python3-pip python3-venv
```

## Terraform Cloud Setup

### Understanding the Structure

**Organization**: Top-level container (e.g., "my-company")
- **Project**: Logical grouping of workspaces (e.g., "infrastructure")
  - **Workspace**: Individual environment state (e.g., "infrastructure-dev")

### Workspace Naming Convention

This template uses: `{project-name}-{environment}`

Examples:
- `infrastructure-dev`
- `infrastructure-staging`
- `infrastructure-prod`

## AWS Configuration

### Option 1: IAM User (Simpler, less secure)

1. Create IAM user in AWS Console
2. Attach policy: `AdministratorAccess` (or custom policy)
3. Generate access keys
4. Provide to setup script or add to Terraform Cloud

### Option 2: IAM Role with OIDC (Recommended for production)

More secure - no long-lived credentials:

1. Create IAM OIDC provider for Terraform Cloud
2. Create IAM role with trust policy
3. Configure in Terraform Cloud workspace settings

See: [Terraform Cloud AWS OIDC Guide](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration)

### Recommended IAM Policy

For production, use least-privilege policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "dynamodb:*",
        "iam:*",
        "cloudwatch:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Running the Setup Script

### Automated Setup

```bash
# Navigate to project root
cd terraform-cloud-template

# Make script executable
chmod +x scripts/setup.sh

# Run setup
./scripts/setup.sh
```

The script will:
1. ✓ Validate prerequisites (Terraform, Python)
2. ✓ Prompt for Terraform Cloud credentials
3. ✓ Create Python virtual environment
4. ✓ Install dependencies
5. ✓ Create project in Terraform Cloud
6. ✓ Create workspaces (dev, staging, prod)
7. ✓ Configure backend files
8. ✓ Optionally set AWS credentials

### Script Prompts

```
Enter Terraform Cloud API Token: [paste token]
Enter Terraform Cloud Organization: my-company
Enter Project Name [infrastructure]: [press Enter or type custom name]

AWS Credentials (optional - can be set later in TFC UI)
AWS Access Key ID: [paste or press Enter to skip]
AWS Secret Access Key: [paste or press Enter to skip]
AWS Region [us-east-1]: [press Enter or type region]
```

### Environment Variables (Alternative)

Instead of interactive prompts:

```bash
export TFC_TOKEN="your-token-here"
export TFC_ORGANIZATION="my-company"
export TFC_PROJECT="infrastructure"
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"

./scripts/setup.sh
```

## Manual Setup (Alternative)

If you prefer manual setup or the script fails:

### 1. Create Project

```bash
# In Terraform Cloud UI
Organization → Projects → New Project
Name: infrastructure
```

### 2. Create Workspaces

For each environment (dev, staging, prod):

```bash
# In Terraform Cloud UI
Projects → infrastructure → New Workspace
Name: infrastructure-dev
Execution Mode: Remote
```

### 3. Configure Backend

Edit each `environments/{env}/backend.tf`:

```hcl
terraform {
  cloud {
    organization = "your-org-name"
    
    workspaces {
      name = "infrastructure-dev"  # or staging, prod
    }
  }
  
  required_version = "~> 1.6.0"
}
```

### 4. Set AWS Credentials

In each workspace:

```
Workspace → Variables → Add variable

Environment Variables:
- AWS_ACCESS_KEY_ID (sensitive)
- AWS_SECRET_ACCESS_KEY (sensitive)
- AWS_DEFAULT_REGION
```

## VCS Integration

Connect GitHub/GitLab for automated runs:

### 1. Connect VCS

```
Organization Settings → Version Control → Add VCS Provider
```

### 2. Configure Workspace

```
Workspace Settings → Version Control
- Connect to repository
- VCS branch: main
- Automatic run triggering: enabled
- Working directory: environments/dev (or staging, prod)
```

### 3. GitHub Actions (Recommended)

Instead of VCS-driven runs, use GitHub Actions for more control:

1. Add `TF_API_TOKEN` to GitHub Secrets
2. Workflows automatically trigger on PR/merge
3. See `.github/workflows/` for examples

## Environment Configuration

### 1. Customize Variables

Copy and edit the example:

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

Update values:

```hcl
tfc_organization = "my-company"
project_name     = "infrastructure"
aws_region       = "us-east-1"

# VPC settings
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Environment-specific
environment = "dev"
enable_nat_gateway = true
single_nat_gateway = true  # Cost saving for dev
```

### 2. Environment-Specific Differences

**Development**:
- Single NAT Gateway (~$33/month)
- Smaller instance types
- Auto-apply enabled
- Minimal redundancy

**Staging**:
- Multi-AZ NAT Gateways (~$100/month)
- Production-like setup
- Manual apply
- Test failover scenarios

**Production**:
- Full high-availability
- Multi-AZ everything
- Manual apply with approval
- Enhanced monitoring

### 3. Authenticate Terraform CLI

After running the setup script, authenticate your local Terraform CLI:

```bash
# From project root or any directory
terraform login
```

**What happens**:
1. Browser opens to Terraform Cloud
2. Generate/copy an API token
3. Paste token in terminal (hidden - just press Enter after pasting)
4. Credentials saved to `~/.terraform.d/credentials.tfrc.json`

**Manual Setup** (if `terraform login` doesn't work):

```bash
# Windows (Git Bash) / Linux / macOS
mkdir -p ~/.terraform.d
cat > ~/.terraform.d/credentials.tfrc.json <<EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR-TOKEN-HERE"
    }
  }
}
EOF
```

Get your token from: https://app.terraform.io/app/settings/tokens

### 4. Initialize and Deploy

When using **remote execution** (default), run from project root:

```bash
# From project root - recommended for remote execution
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

**Why from root?** Remote execution uploads only the working directory. Running from root with `-chdir` ensures `modules/` directory is included.

**Alternative: Local Execution Mode** (for development)

If you prefer to run from within the environment directory:

1. **Change workspace execution mode**:
   - Terraform Cloud → Workspace → Settings → General
   - Execution Mode: "Local"
   - Save

2. **Then run normally**:
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

**Note**: The provided GitHub Actions workflows handle this automatically by running from the repository root.

## Workspace Permissions

### Team Access

Configure in Terraform Cloud:

```
Organization → Teams → Create team

Team permissions:
- Developers: Plan access to dev
- DevOps: Apply access to all
- Viewers: Read access only
```

### Remote State Access

For consuming infrastructure in other workspaces:

```
Workspace Settings → General Settings
- Remote state sharing: Share with specific workspaces
```

Add workspace names that need access (e.g., microservice workspaces).

## Consuming Shared Infrastructure

See [CONSUMING_INFRASTRUCTURE.md](CONSUMING_INFRASTRUCTURE.md) for details on:
- Setting up microservice workspaces
- Using `terraform_remote_state` data source
- Accessing VPC and shared resources
- Best practices for cross-workspace dependencies

## Automation Approach

### Default: GitHub Actions (Recommended for Most Users)

The template includes pre-configured GitHub Actions workflows. This is **API-driven** automation that gives you maximum flexibility.

**Advantages**:
- ✅ Easier initial setup
- ✅ More control over workflows
- ✅ Custom validation steps
- ✅ Works with any Git provider

**Setup**: Just add `TF_API_TOKEN` to GitHub Secrets and push!

### Alternative: VCS-Driven Workflow (Enterprise Option)

For organizations preferring HashiCorp's native approach, you can configure **VCS-driven workflow** where Terraform Cloud directly monitors your repository.

**Advantages**:
- ✅ Native Terraform Cloud integration
- ✅ Simpler team onboarding
- ✅ HashiCorp recommended for enterprise
- ✅ Built-in run queuing

**Setup**: See detailed guide: [VCS Integration](VCS_INTEGRATION.md)

### Which Should You Choose?

**Use the default (GitHub Actions)** unless you specifically need native VCS integration for:
- Enterprise governance requirements
- Sentinel policy enforcement
- Very large teams (50+ people)
- Preference for HashiCorp's recommended approach

Both approaches are production-ready and secure.

## Next Steps

1. ✓ Review [Terraform Cloud Concepts](TERRAFORM_CLOUD.md)
2. ✓ Choose automation approach (default is fine for most)
3. ✓ [Optional] Set up [VCS Integration](VCS_INTEGRATION.md) if preferred
4. ✓ Customize infrastructure for your needs
5. ✓ Create additional modules as needed
6. ✓ Review [Troubleshooting Guide](TROUBLESHOOTING.md)

## Additional Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
