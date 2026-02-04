#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "Terraform Cloud Template Setup"
echo "============================================================"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform is not installed${NC}"
    echo "  Please install from: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed:${NC} $(terraform version | head -n 1)"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python 3 installed:${NC} $(python3 --version)"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}! AWS CLI is not installed${NC}"
    echo -e "${YELLOW}  OIDC setup will be skipped. Install AWS CLI to enable OIDC authentication.${NC}"
    SKIP_OIDC=true
else
    echo -e "${GREEN}✓ AWS CLI installed:${NC} $(aws --version | head -n 1)"
    SKIP_OIDC=false
fi

# Check jq (optional but recommended)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}! jq is not installed (optional, but recommended)${NC}"
else
    echo -e "${GREEN}✓ jq installed${NC}"
fi

# Install Python dependencies
echo -e "\n${YELLOW}Installing Python dependencies...${NC}"
cd scripts
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash)
    source venv/Scripts/activate 2>/dev/null || source venv/bin/activate
else
    # Linux/macOS
    source venv/bin/activate
fi

pip install -q -r requirements.txt
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Get Terraform Cloud credentials
echo -e "\n============================================================"
echo "Terraform Cloud Configuration"
echo "============================================================"
echo "You need a Terraform Cloud account and API token."
echo "Get your token from: https://app.terraform.io/app/settings/tokens"
echo ""

# Check if token already exists in environment
if [ -z "$TFC_TOKEN" ]; then
    read -sp "Enter your Terraform Cloud API Token: " TFC_TOKEN
    echo ""
fi

if [ -z "$TFC_ORGANIZATION" ]; then
    read -p "Enter your Terraform Cloud Organization name: " TFC_ORGANIZATION
fi

if [ -z "$TFC_PROJECT" ]; then
    read -p "Enter Project name [infrastructure]: " TFC_PROJECT
    TFC_PROJECT=${TFC_PROJECT:-infrastructure}
fi

# Export for Python script
export TFC_TOKEN
export TFC_ORGANIZATION
export TFC_PROJECT

# Create Terraform Cloud resources
echo -e "\n${YELLOW}Creating Terraform Cloud workspaces...${NC}"
python3 create-workspace.py

# Check if configuration was created
if [ ! -f "../.tfc-config.json" ]; then
    echo -e "${RED}✗ Configuration file not created${NC}"
    exit 1
fi

# Read configuration
TFC_ORG=$(cat ../.tfc-config.json | python3 -c "import sys, json; print(json.load(sys.stdin)['organization'])")
PROJECT_NAME=$(cat ../.tfc-config.json | python3 -c "import sys, json; print(json.load(sys.stdin)['project'])")

echo -e "\n${GREEN}✓ Terraform Cloud setup complete${NC}"

# Update backend configuration for each environment
echo -e "\n${YELLOW}Updating backend configurations...${NC}"
cd ../

for env in dev staging prod; do
    WORKSPACE_NAME="${PROJECT_NAME}-${env}"
    BACKEND_FILE="environments/${env}/backend.tf"
    
    mkdir -p "environments/${env}"
    
    cat > "$BACKEND_FILE" <<EOF
terraform {
  cloud {
    organization = "${TFC_ORG}"
    
    workspaces {
      name = "${WORKSPACE_NAME}"
    }
  }
  
}
EOF
    
    echo -e "${GREEN}✓ Updated ${BACKEND_FILE}${NC}"
done

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f "terraform.tfvars" ] && [ -f "terraform.tfvars.example" ]; then
    echo -e "\n${YELLOW}Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    
    # Update with actual values
    sed -i.bak "s/my-org/${TFC_ORG}/g" terraform.tfvars
    sed -i.bak "s/infrastructure/${PROJECT_NAME}/g" terraform.tfvars
    rm terraform.tfvars.bak 2>/dev/null || true
    
    echo -e "${GREEN}✓ Created terraform.tfvars${NC}"
    echo -e "${YELLOW}! Please review and update terraform.tfvars with your specific values${NC}"
fi

# Setup AWS OIDC (optional but recommended)
if [ "$SKIP_OIDC" = false ]; then
    echo -e "\n${YELLOW}Setting up AWS OIDC for GitHub Actions...${NC}"
    echo -e "${YELLOW}This will create an IAM role for secure authentication (no long-lived credentials)${NC}"
    
    read -p "Setup AWS OIDC? (Y/n): " SETUP_OIDC
    SETUP_OIDC=${SETUP_OIDC:-Y}
    
    if [[ "$SETUP_OIDC" =~ ^[Yy]$ ]]; then
        # Check AWS credentials
        if ! aws sts get-caller-identity &> /dev/null; then
            echo -e "${RED}✗ AWS credentials not configured${NC}"
            echo -e "${YELLOW}  Run 'aws configure' first${NC}"
        else
            AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            echo -e "${GREEN}✓ AWS credentials valid (Account: ${AWS_ACCOUNT})${NC}"
            
            # Get GitHub info
            read -p "Enter GitHub username/organization: " GITHUB_ORG
            read -p "Enter GitHub repository name [terraform-cloud-template]: " GITHUB_REPO
            GITHUB_REPO=${GITHUB_REPO:-terraform-cloud-template}
            read -p "Enter AWS region [us-west-2]: " AWS_REGION_OIDC
            AWS_REGION_OIDC=${AWS_REGION_OIDC:-us-west-2}
            
            # Create OIDC setup
            cd terraform-aws-oidc
            
            # Create terraform.tfvars
            cat > terraform.tfvars <<EOF
aws_region  = "${AWS_REGION_OIDC}"
role_name   = "GitHubActionsTerraformRole"
github_org  = "${GITHUB_ORG}"
github_repo = "${GITHUB_REPO}"
EOF
            
            # Initialize and apply
            echo -e "\n${YELLOW}Deploying OIDC infrastructure to AWS...${NC}"
            terraform init -upgrade > /dev/null 2>&1
            
            # Check if OIDC provider already exists and import it
            OIDC_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null)
            if [ ! -z "$OIDC_ARN" ]; then
                echo -e "${YELLOW}OIDC provider already exists, importing...${NC}"
                terraform import aws_iam_openid_connect_provider.github_actions "$OIDC_ARN" > /dev/null 2>&1 || true
            fi
            
            echo -e "${YELLOW}Running terraform apply...${NC}"
            if terraform apply -auto-approve 2>&1 | tee /tmp/terraform-oidc.log; then
                ROLE_ARN=$(terraform output -raw github_actions_role_arn)
                echo -e "\n${GREEN}✓ OIDC setup complete!${NC}"
                echo -e "\n${GREEN}============================================================"
                echo "AWS Role ARN: ${ROLE_ARN}"
                echo "============================================================${NC}"
                echo -e "\n${YELLOW}📋 Add this to GitHub Secrets:${NC}"
                echo "   1. Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
                echo "   2. Click 'New repository secret'"
                echo "   3. Name: AWS_ROLE_ARN"
                echo "   4. Value: ${ROLE_ARN}"
                echo ""
            else
                echo -e "${RED}✗ OIDC setup failed${NC}"
                echo -e "\n${YELLOW}Error details:${NC}"
                tail -20 /tmp/terraform-oidc.log
                echo -e "\n${YELLOW}To fix manually:${NC}"
                echo "  cd terraform-aws-oidc"
                echo "  terraform apply"
            fi
            
            cd ..
        fi
    fi
fi

# Summary
echo -e "\n============================================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "============================================================"
echo "Organization: ${TFC_ORG}"
echo "Project: ${PROJECT_NAME}"
echo "Workspaces: ${PROJECT_NAME}-dev, ${PROJECT_NAME}-staging, ${PROJECT_NAME}-prod"
echo ""
echo -e "${GREEN}============================================================"
echo "🎉 Terraform Cloud Setup Complete!"
echo "============================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""

if [ ! -z "$ROLE_ARN" ]; then
    echo -e "${GREEN}✅ AWS OIDC is configured!${NC}"
    echo ""
    echo -e "${YELLOW}1️⃣  ADD ROLE ARN TO GITHUB SECRETS:${NC}"
    echo "   • Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
    echo "   • Name: AWS_ROLE_ARN"
    echo "   • Value: ${ROLE_ARN}"
    echo ""
    echo -e "${YELLOW}2️⃣  CREATE GITHUB ENVIRONMENTS (OPTIONAL):${NC}"
else
    echo -e "${RED}⚠️  AWS authentication not configured${NC}"
    echo ""
    echo -e "${YELLOW}Option A: Use OIDC (Recommended):${NC}"
    echo "   cd terraform-aws-oidc"
    echo "   terraform apply"
    echo "   # Then add AWS_ROLE_ARN to GitHub Secrets"
    echo ""
    echo -e "${YELLOW}1️⃣  CREATE GITHUB ENVIRONMENTS (OPTIONAL):${NC}"
fi
echo "   • Go to: https://github.com/[YOUR-ORG]/[YOUR-REPO]/settings/environments"
echo "   • Click 'New environment' → Name: 'dev' → Configure"
echo "     └─ Leave all protection rules unchecked (auto-deploy)"
echo "   • Click 'New environment' → Name: 'staging' → Configure"
echo "     └─ Enable 'Required reviewers' → Add yourself or team"
echo "   • Click 'New environment' → Name: 'prod' → Configure"
echo "     └─ Enable 'Required reviewers' → Add 2+ reviewers"
echo "     └─ Enable 'Prevent self-review'"
echo "     └─ Optional: Add 'Wait timer: 10 minutes'"
echo ""
echo "2️⃣  CREATE TEAM TOKEN IN TERRAFORM CLOUD:"
echo "   • Go to: https://app.terraform.io/app/${TFC_ORG}/settings/authentication-tokens?tabIndex=1"
echo "   • Click 'Create a team' → Name: 'github-actions'"
echo "   • Click on the team → 'Team API Token' tab"
echo "   • Click 'Create a team token'"
echo "   • Expiration: Select 'Never' (or 1 year)"
echo "   • Copy the token (you won't see it again!)"
echo ""
echo "3️⃣  ADD TOKEN TO GITHUB SECRETS:"
echo "   • Go to your GitHub repo → Settings → Secrets and variables → Actions"
echo "   • Click 'New repository secret'"
echo "   • Name: TF_API_TOKEN"
echo "   • Value: [Paste the team token from step 1]"
echo "   • Click 'Add secret'"
echo ""
echo "4️⃣  PUSH YOUR CODE:"
echo "   git add ."
echo "   git commit -m \"Initial infrastructure setup\""
echo "   git push origin main"
echo ""
echo "   GitHub Actions will automatically deploy! 🚀"
echo ""
echo -e "${YELLOW}📖 Alternative: Local CLI Testing${NC}"
echo ""
echo "If you want to test locally first:"
echo "   terraform login"
echo "   terraform -chdir=environments/dev init"
echo "   terraform -chdir=environments/dev plan"
echo ""
echo -e "${GREEN}============================================================"
echo "📚 Documentation:"
echo "   • GitHub Environments: docs/GITHUB_ENVIRONMENTS.md"
echo "   • Troubleshooting: docs/TROUBLESHOOTING.md"
echo "   • README: README.md"
echo "============================================================${NC}"
