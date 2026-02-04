# AWS OIDC for GitHub Actions

This Terraform configuration creates:
- **OIDC Provider**: Allows GitHub Actions to authenticate with AWS
- **IAM Role**: Role that GitHub Actions assumes to deploy infrastructure
- **IAM Policy**: Permissions for Terraform to manage AWS resources

## Automatic Setup

The `../scripts/setup.sh` script automatically:
1. Creates `terraform.tfvars` with your values
2. Imports existing OIDC provider (if it exists)
3. Deploys the IAM role
4. Outputs the role ARN for GitHub Secrets

## Manual Setup

If needed, you can run this manually:

```bash
cd terraform-aws-oidc

# Create config
cp terraform.tfvars.example terraform.tfvars
# Edit: Set your github_org, github_repo

# Deploy
terraform init
terraform apply

# Get role ARN
terraform output github_actions_role_arn
```

## What Gets Created

1. **OIDC Provider** (or uses existing)
   - URL: `https://token.actions.githubusercontent.com`
   - Trusted by: `sts.amazonaws.com`

2. **IAM Role**: `GitHubActionsTerraformRole`
   - Trust policy: Only your GitHub repository
   - Permissions: EC2, VPC, S3, DynamoDB, IAM (limited), Logs

3. **Security**: Role can only be assumed by GitHub Actions from your specific repository

## Troubleshooting

**"Provider already exists"** - Fixed! Script now imports existing provider

**"Not authorized"** - Check your AWS CLI is configured: `aws configure`

**"Access denied"** - Ensure your AWS user has IAM admin permissions
