# Terraform Cloud Template

A production-ready template for quickly setting up infrastructure with Terraform Cloud. This template automates the creation of Terraform Cloud workspaces and provides best-practice AWS infrastructure modules.

## 🚀 Features

- **Zero-friction Setup**: Single command creates entire Terraform Cloud workspace structure
- **Security-First**: Comprehensive `.gitignore` preventing secret exposure
- **Multi-Environment**: Separate workspaces for dev, staging, and production
- **AWS Best Practices**: Production-ready VPC, compute, and storage modules
- **CI/CD Ready**: GitHub Actions workflows for automated validation and deployment
- **Remote State**: Shared infrastructure via Terraform Cloud remote state
- **Microservice Pattern**: Example for consuming shared infrastructure in separate repos

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads) (>= 1.6.0)
- [Terraform Cloud Account](https://app.terraform.io/signup/account) (free tier available)
- [AWS Account](https://aws.amazon.com/)
- Python 3.7+
- Git

## ⚡ Quick Start

### 1. Use This Template

Click "Use this template" on GitHub or clone this repository:

```bash
git clone <your-repo-url>
cd terraform-cloud-template
```

### 2. Run Automated Setup

The setup script will:
- Validate prerequisites (Terraform, Python, AWS CLI)
- Create Terraform Cloud project and workspaces
- Configure backend for each environment
- **Set up AWS OIDC authentication** (recommended)

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

You'll be prompted for:
- Terraform Cloud API token
- Organization and project name
- **AWS OIDC setup** (auto-creates IAM role)
- GitHub repository details

### 3. Customize Configuration

Review and update `terraform.tfvars` with your specific settings:

```bash
# The setup script creates this from terraform.tfvars.example
vi terraform.tfvars
```

### 4. Set Up GitHub Secrets

If setup script configured OIDC (recommended):
```bash
# Add to GitHub Secrets:
# Settings → Secrets → Actions → New secret
# Name: AWS_ROLE_ARN
# Value: <from setup output>
```

Also add Terraform Cloud token:
```bash
# Name: TF_API_TOKEN  
# Value: <team token from Terraform Cloud>
```

### 5. Deploy

```bash
git add .
git commit -m "Initial setup"
git push origin main
```

GitHub Actions will automatically deploy infrastructure! 🚀

## 📁 Project Structure

```
terraform-cloud-template/
├── README.md                    # This file
├── .gitignore                   # Prevents committing secrets
├── terraform.tfvars.example     # Example configuration
├── scripts/
│   ├── setup.sh                 # Automated setup script
│   ├── create-workspace.py      # Terraform Cloud API automation
│   └── requirements.txt         # Python dependencies
├── .github/workflows/           # CI/CD pipelines
│   ├── terraform-plan.yml       # PR validation
│   ├── terraform-apply.yml      # Auto-deploy on merge
│   └── terraform-validate.yml   # Format and validation
├── environments/
│   ├── dev/                     # Development environment
│   ├── staging/                 # Staging environment
│   └── prod/                    # Production environment
├── modules/
│   ├── vpc/                     # Multi-AZ VPC module
│   ├── compute/                 # Auto-scaling compute module
│   └── storage/                 # S3 and DynamoDB module
└── docs/
    ├── SETUP_GUIDE.md           # Detailed setup instructions
    ├── TERRAFORM_CLOUD.md       # Terraform Cloud concepts
    ├── CONSUMING_INFRASTRUCTURE.md  # Remote state guide
    └── TROUBLESHOOTING.md       # Common issues and solutions
```

## 🏗️ Infrastructure Modules

### VPC Module
Creates a production-ready VPC with:
- Multi-AZ deployment (3 availability zones)
- Public and private subnets
- NAT Gateway(s) for private subnet internet access
- Internet Gateway for public subnets
- VPC Flow Logs (optional)

**Cost optimization**: Use `single_nat_gateway = true` for dev (~$33/month vs ~$100/month for multi-AZ)

### Compute Module (Optional)
- Auto Scaling Group with Launch Template
- Security Groups with HTTP/HTTPS access
- IAM role with SSM access (no SSH keys needed!)
- Auto-scaling based on CPU utilization

### Storage Module (Optional)
- S3 bucket with encryption and versioning
- Lifecycle rules for cost optimization
- DynamoDB table with encryption
- Public access blocked by default

## 🔄 CI/CD Integration

This template provides **two automation approaches**. Choose based on your organization's needs:

### Default: GitHub Actions (API-Driven) with Environment Protection

**Best for**: Flexibility, custom workflows, multi-tool integration, deployment approvals

Pre-configured workflows included:
- **On Pull Request** (`terraform-plan.yml`): Validates and plans changes, posts to PR
- **On Merge** (`terraform-apply.yml`): Automatically applies with environment protection
  - **Dev**: Auto-deploys immediately ✅
  - **Staging**: Requires 1 approval ⏸️
  - **Prod**: Requires 2 approvals + wait timer ⏸️

**Setup**:
1. **Create GitHub Environments** (5 minutes)
   ```
   Settings → Environments → New environment
   
   Create: dev (no protection)
           staging (1 reviewer required)
           prod (2 reviewers + wait timer)
   ```
2. Add `TF_API_TOKEN` to GitHub Secrets (Settings → Secrets → Actions)
3. Push to GitHub - workflows run automatically!

📖 **[Full Setup Guide: GitHub Environments](docs/GITHUB_ENVIRONMENTS.md)**

### Alternative: VCS-Driven Workflow (Enterprise)

**Best for**: Native Terraform Cloud integration, simpler team setup, enterprise governance

**How it works**: Terraform Cloud directly monitors your Git repository and auto-triggers runs on push.

**Setup**: See [VCS Integration Guide](docs/VCS_INTEGRATION.md)

### Which Should I Use?

| Use GitHub Actions If... | Use VCS-Driven If... |
|--------------------------|----------------------|
| ✅ Need custom validation | ✅ Want simplest setup |
| ✅ Complex approval flows | ✅ Prefer HashiCorp native |
| ✅ Multi-tool integration | ✅ Enterprise governance focus |
| ✅ Maximum flexibility | ✅ Large distributed teams |

**Both approaches are production-ready.** The default (GitHub Actions) offers more flexibility, while VCS-driven provides tighter Terraform Cloud integration. 

📊 **Need help deciding?** See [Workflow Comparison Guide](docs/WORKFLOW_COMPARISON.md) for detailed analysis by team size, use case, and requirements.

## 🔐 Security Best Practices

### AWS Authentication (OIDC)

**Setup script automatically configures OIDC:**
- ✅ No long-lived credentials
- ✅ Automatic credential rotation  
- ✅ Enhanced security
- ✅ AWS best practice

The `setup.sh` script will:
1. Check for AWS CLI
2. Create OIDC provider in AWS
3. Create IAM role with Terraform permissions
4. Output role ARN for GitHub Secrets

**Environment Control**: By default, only `dev` is enabled. Enable `staging` and `prod` when ready - see [ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md)

### Secrets Management
- **NEVER** commit `terraform.tfvars` or any files with credentials
- The `.gitignore` is pre-configured to block common secret files
- Use GitHub Secrets for CI/CD tokens only (not AWS credentials with OIDC)

### What's Protected
The `.gitignore` prevents committing:
- Terraform state files
- Variable files with secrets
- AWS credentials
- SSH keys
- Environment files (`.env`)
- Terraform Cloud tokens

## 🔗 Consuming Shared Infrastructure

See [`example-microservice/`](../example-microservice) for a complete example of how to consume the VPC and other shared resources in a separate microservice repository.

Key concept: Use `terraform_remote_state` data source to read outputs from this infrastructure:

```hcl
data "terraform_remote_state" "shared_infra" {
  backend = "remote"
  
  config = {
    organization = "your-org"
    workspaces = {
      name = "infrastructure-dev"
    }
  }
}

# Access shared VPC
resource "aws_security_group" "app" {
  vpc_id = data.terraform_remote_state.shared_infra.outputs.vpc_id
  # ...
}
```

For detailed guidance, see [docs/CONSUMING_INFRASTRUCTURE.md](docs/CONSUMING_INFRASTRUCTURE.md)

## 📚 Documentation

- **[Setup Guide](docs/SETUP_GUIDE.md)** - Detailed setup instructions and configuration
- **[Token Management](docs/TOKEN_MANAGEMENT.md)** - Managing and rotating Terraform Cloud tokens
- **[GitHub Environments](docs/GITHUB_ENVIRONMENTS.md)** - Deployment approvals and protection ⭐
- **[CLI Usage](docs/CLI_USAGE.md)** - How to use Terraform CLI with this template
- **[Local Testing](docs/LOCAL_TESTING.md)** - Test configurations locally without Terraform Cloud
- **[Workflow Comparison](docs/WORKFLOW_COMPARISON.md)** - GitHub Actions vs VCS-driven: which to choose?
- **[VCS Integration](docs/VCS_INTEGRATION.md)** - Enterprise VCS-driven workflow setup guide
- **[Terraform Cloud Concepts](docs/TERRAFORM_CLOUD.md)** - Understanding workspaces, projects, and state
- **[Consuming Infrastructure](docs/CONSUMING_INFRASTRUCTURE.md)** - How to use shared resources
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🛠️ Common Commands

```bash
# Initialize Terraform (run once per environment)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy all resources (careful!)
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## 🌍 Multi-Environment Strategy

Each environment has:
- Separate Terraform Cloud workspace
- Isolated state file
- Different CIDR blocks (dev: 10.0.x.x, staging: 10.1.x.x, prod: 10.2.x.x)
- Environment-specific variables

**Cost optimization**:
- Dev: Single NAT gateway, smaller instances
- Staging: Multi-AZ for testing failover
- Prod: Full high-availability setup

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt -recursive`
4. Create a pull request
5. Review the Terraform plan in PR comments
6. Merge after approval

## 📝 License

This template is provided as-is for use in your projects.

## 🆘 Support

- Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Note**: This template uses Terraform Cloud for remote state management. You can modify it to use other backends (S3, Consul, etc.) by changing the backend configuration in `environments/*/backend.tf`.
