# Quick Start Guide

Get your Terraform Cloud infrastructure up and running in 5 minutes!

## Prerequisites Checklist

- [ ] [Terraform Cloud account](https://app.terraform.io/signup/account) (free)
- [ ] [Terraform CLI](https://www.terraform.io/downloads) installed
- [ ] AWS account with credentials
- [ ] Python 3.7+ installed
- [ ] Git installed

## Step-by-Step Setup

### 1. Get Terraform Cloud Token

1. Go to https://app.terraform.io/app/settings/tokens
2. Click "Create an API token"
3. Copy the token (you'll need this in step 3)

### 2. Clone This Repository

```bash
git clone <your-repo-url>
cd terraform-cloud-template
```

### 3. Run Setup Script

```bash
# Make script executable
chmod +x scripts/setup.sh

# Run setup (follow prompts)
./scripts/setup.sh
```

**What the script does:**
- ✓ Validates prerequisites
- ✓ Creates Terraform Cloud project
- ✓ Creates workspaces (dev, staging, prod)
- ✓ Configures backend files
- ✓ Sets AWS credentials (optional)

### 4. Authenticate Terraform CLI

The setup script configured Terraform Cloud, but your local CLI needs authentication:

```bash
# Authenticate (opens browser)
terraform login

# Follow prompts:
# 1. Browser opens to app.terraform.io
# 2. Click "Create an API token"
# 3. Copy the token
# 4. Paste in terminal (won't show - that's normal)
# 5. Press Enter
```

**✅ You're now authenticated!**

### 5. Customize Configuration

```bash
# Edit variables (created by setup script)
vi terraform.tfvars

# Key settings:
# - aws_region: Your preferred AWS region
# - vpc_cidr: Network CIDR block
# - environment: dev, staging, or prod
```

### 6. Deploy Dev Environment

**Important**: Run Terraform from the project root using `-chdir` to ensure modules are accessible:

```bash
# From project root (don't cd into environments/dev)
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

**Why `-chdir`?** When using remote execution (Terraform Cloud), only the specified directory and its subdirectories are uploaded. Using `-chdir` from the root ensures the `modules/` directory is included.

**Alternative for development** (local execution):

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

Requires setting workspace to "Local" execution mode in Terraform Cloud UI.

**⏱️ Deployment time:** ~5-10 minutes

### 7. Verify Deployment

```bash
# Check outputs
terraform output

# You should see:
# - vpc_id
# - private_subnet_ids
# - public_subnet_ids
# - etc.
```

## What Gets Created

### Default Resources (Dev Environment)

- ✅ VPC with CIDR 10.0.0.0/16
- ✅ 3 Public subnets (multi-AZ)
- ✅ 3 Private subnets (multi-AZ)
- ✅ Internet Gateway
- ✅ 1 NAT Gateway (cost optimized for dev)
- ✅ Route tables and associations

**💰 Estimated cost:** ~$35-40/month for dev environment

## Next Steps

### Deploy to Other Environments

```bash
# Staging
cd environments/staging
terraform init
terraform apply

# Production (review carefully!)
cd environments/prod
terraform init
terraform plan  # Review thoroughly!
terraform apply
```

### Add CI/CD Automation

**Option 1: GitHub Actions with Environment Protection (Recommended)**

Follow the setup script output or these steps:

1. **Create GitHub Environments** (protects staging/prod):
   ```
   Settings → Environments → New environment
   
   - dev: No protection (auto-deploy)
   - staging: Add 1 reviewer
   - prod: Add 2 reviewers + wait timer
   ```

2. **Create Terraform Cloud Team Token**:
   - Go to: https://app.terraform.io/app/[YOUR-ORG]/settings/authentication-tokens
   - Create team: `github-actions`
   - Grant team access to workspaces (Write permission)
   - Create team token (never expires)

3. **Add token to GitHub Secrets**:
   - Repository Settings → Secrets → Actions
   - New secret: `TF_API_TOKEN`
   - Value: Your team token

4. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initial setup"
   git push origin main
   ```

**Result:**
- ✅ Dev deploys automatically
- ⏸️ Staging waits for approval
- ⏸️ Prod requires 2 approvals + 10-min wait

📖 **[Detailed Guide: GitHub Environments](docs/GITHUB_ENVIRONMENTS.md)**

**Option 2: VCS-Driven Workflow (Enterprise Alternative)**

Connect Terraform Cloud directly to your repository for native integration:
- Simpler for large teams
- HashiCorp recommended approach
- See [VCS Integration Guide](docs/VCS_INTEGRATION.md) for setup

**Both options are production-ready.** Choose based on your needs:
- GitHub Actions: More flexible, deployment approvals, custom workflows
- VCS-Driven: Simpler, native Terraform Cloud integration

### Deploy a Microservice

```bash
# Copy example microservice
cp -r example-microservice ../my-app

# Customize
cd ../my-app
vi backend.tf  # Update organization and workspace name
vi terraform.tfvars.example
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars  # Set your values

# Enable remote state sharing
# In Terraform Cloud UI:
# 1. Go to infrastructure-dev workspace
# 2. Settings → General → Remote state sharing
# 3. Add your microservice workspace name

# Deploy
terraform init
terraform apply
```

## Common First-Time Issues

### "Command not found: terraform"

```bash
# Install Terraform
# macOS:
brew install terraform

# Windows (Chocolatey):
choco install terraform

# Linux:
# See https://www.terraform.io/downloads
```

### "Python module not found"

```bash
cd scripts
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
./setup.sh  # Run again
```

### "AWS credentials not configured"

```bash
# Option 1: Let setup script configure them
# It will prompt for AWS credentials

# Option 2: Set manually in Terraform Cloud
# Workspace → Variables → Add Environment Variables:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_DEFAULT_REGION
```

### "Organization not found"

Make sure you're using the exact organization name from Terraform Cloud UI.

### "Unauthorized" when running terraform init

**Cause**: Terraform CLI not authenticated with Terraform Cloud

**Solution**:
```bash
# Authenticate your CLI
terraform login

# Then retry
terraform init
```

**Manual alternative** (if browser doesn't work):
```bash
# Create credentials file
mkdir -p ~/.terraform.d
cat > ~/.terraform.d/credentials.tfrc.json <<EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR-TOKEN-FROM-TFC"
    }
  }
}
EOF
```

## Architecture Overview

```
Terraform Cloud
├── Project: infrastructure
│   ├── Workspace: infrastructure-dev
│   ├── Workspace: infrastructure-staging
│   └── Workspace: infrastructure-prod
```

Each workspace manages:
- Separate VPC and network
- Isolated state file
- Environment-specific variables

## File Structure

```
terraform-cloud-template/
├── scripts/setup.sh           # 🚀 Start here!
├── environments/
│   ├── dev/                   # Development environment
│   ├── staging/               # Staging environment
│   └── prod/                  # Production environment
├── modules/
│   ├── vpc/                   # Network infrastructure
│   ├── compute/               # EC2/ECS resources (optional)
│   └── storage/               # S3/DynamoDB (optional)
├── example-microservice/      # Example app consuming shared infra
└── docs/                      # Detailed documentation
```

## Quick Commands Reference

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# View specific output
terraform output vpc_id

# Destroy everything (careful!)
terraform destroy
```

## Cost Optimization Tips

**Development:**
```hcl
single_nat_gateway = true   # $32/mo instead of $96/mo
instance_type = "t3.micro"  # Smaller instances
```

**Production:**
```hcl
single_nat_gateway = false  # High availability
instance_type = "t3.medium" # Appropriate sizing
```

## Getting Help

1. **Documentation:** Check `docs/` directory
   - `SETUP_GUIDE.md` - Detailed setup
   - `TROUBLESHOOTING.md` - Common issues
   - `TERRAFORM_CLOUD.md` - Concepts explained

2. **Terraform Cloud UI:** Excellent debugging info
   - View run history
   - Check state versions
   - Review plan output

3. **Community:**
   - [Terraform Forum](https://discuss.hashicorp.com/c/terraform-core)
   - [AWS Forums](https://repost.aws/)

## Success Checklist

- [ ] Setup script completed successfully
- [ ] Dev environment deployed
- [ ] Can see outputs with `terraform output`
- [ ] Terraform Cloud shows successful run
- [ ] AWS Console shows created VPC and subnets
- [ ] GitHub Actions workflows configured (optional)
- [ ] Example microservice deployed (optional)

## What's Next?

1. **Customize modules** for your needs
2. **Add more environments** (QA, demo, etc.)
3. **Deploy applications** using example-microservice pattern
4. **Set up monitoring** and alerting
5. **Implement backup strategies**
6. **Configure cost alerts** in AWS

---

**🎉 Congratulations!** You now have production-ready infrastructure-as-code with Terraform Cloud!

For detailed information, see the [main README](README.md) and [documentation](docs/).
