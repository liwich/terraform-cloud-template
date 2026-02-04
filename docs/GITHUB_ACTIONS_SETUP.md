# GitHub Actions Setup Guide

Quick reference for setting up CI/CD after running the setup script.

## ✅ Prerequisites

You should have already run:
```bash
./scripts/setup.sh
```

This created your Terraform Cloud workspaces. Now let's connect GitHub Actions!

---

## 🚀 5-Minute Setup

### Step 1: Create Team Token in Terraform Cloud

1. **Go to Teams Page**:
   - https://app.terraform.io/app/YOUR-ORG/settings/teams
   - Replace `YOUR-ORG` with your organization name

2. **Create New Team**:
   - Click **"Create a team"**
   - Name: `github-actions`
   - Click **"Create team"**

3. **Generate Team Token**:
   - Click on the `github-actions` team
   - Click **"Team API Token"** tab
   - Click **"Create a team token"**
   - Description: `GitHub Actions CI/CD`
   - **Expiration: Never** (recommended) or set to 1 year
   - Click **"Create team token"**
   - **⚠️ COPY THE TOKEN NOW** - you won't see it again!

### Step 2: Grant Team Access to Workspaces

Give the team access to all three workspaces:

**For infrastructure-dev**:
1. Go to: https://app.terraform.io/app/YOUR-ORG/workspaces/infrastructure-dev/settings/access
2. Click **"Add team and permissions"**
3. Select: `github-actions`
4. Permission: **Write**
5. Click **"Add team"**

**Repeat for**:
- `infrastructure-staging`
- `infrastructure-prod`

💡 **Tip**: You can use different permissions per environment:
- Dev: `Write` (auto-deploy)
- Staging: `Write` (auto-deploy)
- Prod: `Plan` (manual approval required)

### Step 3: Add Token to GitHub Secrets

1. **Go to your GitHub repository**

2. **Navigate to Secrets**:
   - Click **Settings** (top menu)
   - Click **Secrets and variables** → **Actions** (left sidebar)

3. **Create New Secret**:
   - Click **"New repository secret"**
   - Name: `TF_API_TOKEN`
   - Value: [Paste the team token from Step 1]
   - Click **"Add secret"**

### Step 4: Push Your Code

```bash
# From project root
git add .
git commit -m "Initial Terraform Cloud infrastructure"
git push origin main
```

### Step 5: Watch It Deploy! 🎉

1. Go to your GitHub repository
2. Click **"Actions"** tab
3. You'll see the workflow running
4. Click on it to watch the deployment in real-time

---

## 🎯 What Happens Next?

### On Every Pull Request

GitHub Actions will:
- ✅ Check Terraform formatting
- ✅ Validate configuration
- ✅ Run `terraform plan`
- ✅ Post plan output as PR comment

### On Every Push to Main

GitHub Actions will:
- ✅ Detect which environments changed
- ✅ Run `terraform plan`
- ✅ Run `terraform apply` automatically
- ✅ Show deployment summary

---

## 🔒 Security Best Practices

### Token Management

✅ **Do**:
- Use team tokens (not user tokens) for CI/CD
- Set expiration or rotate every 90 days
- Store only in GitHub Secrets
- Grant minimum required permissions

❌ **Don't**:
- Commit tokens to Git
- Share tokens in chat/email
- Use same token for multiple purposes

### Branch Protection (Recommended)

Protect your `main` branch:

1. **GitHub repo → Settings → Branches**
2. **Add rule** for `main`:
   - ✅ Require pull request reviews before merging (at least 1)
   - ✅ Require status checks to pass before merging
     - Select: `Terraform Plan - dev`
   - ✅ Require branches to be up to date before merging
3. **Create**

Now all changes require:
- Code review
- Successful Terraform plan
- Then auto-deploy on merge

---

## 🧪 Testing the Setup

### Test 1: Create a Pull Request

```bash
# Create a test branch
git checkout -b test-ci-cd

# Make a small change
echo "# Test" >> environments/dev/main.tf

# Commit and push
git add environments/dev/main.tf
git commit -m "Test: GitHub Actions integration"
git push origin test-ci-cd

# Create PR on GitHub
```

**Expected Result**:
- GitHub Actions runs automatically
- Terraform plan appears in PR comments
- Status check shows success/failure

### Test 2: Merge and Deploy

```bash
# Merge the PR on GitHub
# (Or from command line)
git checkout main
git merge test-ci-cd
git push origin main
```

**Expected Result**:
- GitHub Actions runs automatically
- Terraform apply executes
- Infrastructure is deployed
- Summary appears in Actions tab

---

## 🔧 Troubleshooting

### "Error: 401 Unauthorized"

**Problem**: Token not valid or not set

**Solution**:
```bash
# 1. Verify token in GitHub Secrets
GitHub → Settings → Secrets → Actions → TF_API_TOKEN

# 2. Regenerate if needed
Terraform Cloud → Teams → github-actions → Create new token

# 3. Update GitHub Secret
```

### "Error: Workspace access denied"

**Problem**: Team doesn't have access to workspace

**Solution**:
```bash
# Grant team access to workspace
Workspace → Settings → Team Access → Add 'github-actions' team
```

### Workflow Not Triggering

**Problem**: Workflow not running on push

**Solution**:
```bash
# 1. Check workflows exist
ls -la .github/workflows/

# 2. Verify paths in workflow
# Edit .github/workflows/terraform-apply.yml
# Check 'paths:' section matches your changes

# 3. Check Actions tab in GitHub
# Look for any error messages
```

### Plan Shows No Changes

**Problem**: Terraform plan shows no resources to create

**Solution**:
```bash
# This is normal! The VPC module will create resources
# On first apply, you should see:
# - VPC
# - Subnets
# - NAT Gateway
# - Internet Gateway
# - Route tables

# If truly no changes, check:
# 1. Correct workspace selected
# 2. No previous deployment
# 3. Configuration is correct
```

---

## 📊 Workflow Files

### Included Workflows

The template includes these workflows:

**`.github/workflows/terraform-plan.yml`**:
- Triggers: Pull requests to `main`
- Actions: Format check, validate, plan
- Posts: Plan output as PR comment

**`.github/workflows/terraform-apply.yml`**:
- Triggers: Push to `main`
- Actions: Plan and apply changes
- Environments: Auto-detects changed environments

**`.github/workflows/terraform-validate.yml`**:
- Triggers: All pushes and PRs
- Actions: Format check, validate all modules

### Customizing Workflows

To modify behavior, edit the workflow files:

```yaml
# Example: Require manual approval for prod
# In .github/workflows/terraform-apply.yml

jobs:
  terraform-apply:
    environment:
      name: ${{ matrix.environment }}  # Requires environment approval
```

Then create environment in GitHub with approval:
- Settings → Environments → New environment: `prod`
- Add required reviewers

---

## 🎓 Next Steps

### Learn More

- **[Token Management](docs/TOKEN_MANAGEMENT.md)** - Rotating and managing tokens
- **[Workflow Comparison](docs/WORKFLOW_COMPARISON.md)** - GitHub Actions vs VCS-driven
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues

### Enhance Your Setup

1. **Add Approval Gates**:
   - Require manual approval for prod deployments
   - Settings → Environments → Create `prod` environment

2. **Add Notifications**:
   - Slack/Teams notifications on deployment
   - Terraform Cloud → Workspace → Settings → Notifications

3. **Add Cost Estimation**:
   - Automatically enabled in Terraform Cloud
   - Shows cost impact in plan output

4. **Add Security Scanning**:
   - Use tools like tfsec, checkov
   - Add to GitHub Actions workflow

---

## ✅ Checklist

Use this to verify your setup:

- [ ] Created `github-actions` team in Terraform Cloud
- [ ] Generated team token (copied and saved)
- [ ] Granted team access to all workspaces (dev, staging, prod)
- [ ] Added `TF_API_TOKEN` to GitHub Secrets
- [ ] Pushed code to GitHub
- [ ] Workflow ran successfully in Actions tab
- [ ] (Optional) Set up branch protection
- [ ] (Optional) Created prod environment with approvals

---

## 🎉 Success!

Once you see this in GitHub Actions:

```
✅ Terraform Plan - dev
✅ Terraform Apply - dev
Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

**Your CI/CD pipeline is working!** 🚀

Every future change will be:
- Reviewed in pull requests
- Planned automatically
- Deployed on merge
- Tracked in Terraform Cloud

Welcome to automated infrastructure management! 🎊
