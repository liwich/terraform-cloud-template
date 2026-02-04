# GitHub Environments Setup Guide

This guide explains how to set up GitHub Environments for deployment protection and manual approvals.

##  Table of Contents

- [What Are GitHub Environments?](#what-are-github-environments)
- [Quick Setup](#quick-setup)
- [Environment Protection Rules](#environment-protection-rules)
- [Deployment Workflow](#deployment-workflow)
- [Best Practices](#best-practices)

---

## What Are GitHub Environments?

GitHub Environments provide:

- ** Protection Rules** - Require approvals before deployment
- ** Deployment History** - Track all deployments per environment
- ** Environment Secrets** - Scope secrets to specific environments
- **⏰ Wait Timers** - Add delays before deployment
- ** Reviewers** - Require specific people/teams to approve

---

## Quick Setup

### 1. Create Environments in GitHub

Go to your repository:

```
Settings → Environments → New environment
```

Create three environments:
1. **`dev`** - No protection (auto-deploy)
2. **`staging`** - Require approval
3. **`prod`** - Require approval + additional rules

### 2. Configure Protection Rules

#### **Dev Environment** (No Protection)

```
Environment name: dev
Protection rules: None
 Allow administrators to bypass
```

**Why?** Dev should deploy automatically for fast iteration.

---

#### **Staging Environment** (Require Approval)

```
Environment name: staging

Protection rules:
 Required reviewers (1-6 reviewers)
   └─ Select: Your team or specific users
   
Optional:
□ Prevent self-review
□ Wait timer: 0 minutes
 Allow administrators to bypass (for emergencies)
```

**Recommended Reviewers:**
- Team lead
- Senior engineers
- Platform/DevOps team

---

#### **Prod Environment** (Maximum Protection)

```
Environment name: prod

Protection rules:
 Required reviewers (2-6 reviewers)
   └─ Select: Senior engineers + team lead
   
 Prevent self-review (person who triggered can't approve)

Optional but recommended:
 Wait timer: 10 minutes (cooling-off period)
 Deployment branches: Only 'main' branch
 Allow administrators to bypass (for emergencies)
```

**Recommended Reviewers:**
- 2+ senior engineers
- Team lead or engineering manager
- Platform/DevOps team lead

---

## Environment Protection Rules

### Required Reviewers

**Purpose:** Require manual approval before deployment

**Configuration:**

1. Go to: `Settings → Environments → [environment] → Required reviewers`
2. Click "Add reviewers"
3. Select:
   - Individual users
   - Teams (recommended for easier management)
4. Set number of required approvals (1-6)

**Example Teams:**

```
dev:      No reviewers (auto-deploy)
staging:  @engineering-team (1 approval)
prod:     @senior-engineers (2 approvals)
```

---

### Prevent Self-Review

**Purpose:** Prevent the person who triggered the deployment from approving it

**When to use:**
-  Production environment (always)
-  Staging environment (recommended)
-  Dev environment (not needed)

---

### Wait Timer

**Purpose:** Add a mandatory delay before deployment

**When to use:**
- Production deployments (5-15 minutes)
- Gives time to catch mistakes before they deploy

**Example:**
```
dev:      0 minutes (no delay)
staging:  0 minutes (approval is enough)
prod:     10 minutes (cooling-off period)
```

---

### Deployment Branches

**Purpose:** Restrict which branches can deploy to this environment

**Configuration:**

```
dev:      All branches
staging:  main + release/* branches
prod:     main branch only
```

**How to set:**

1. Go to: `Settings → Environments → [environment] → Deployment branches`
2. Select:
   - **Protected branches only** (strict)
   - **Selected branches** (custom rules)
   - **All branches** (dev only)

---

## Deployment Workflow

### 1. Push to Main Branch

```bash
git push origin main
```

### 2. Dev Deploys Automatically

```
 Dev environment: Deploys immediately (no approval needed)
```

You'll see in GitHub Actions:
```
Apply - dev:  Running
Apply - staging: ⏸  Waiting for approval
Apply - prod: ⏸  Waiting for approval
```

---

### 3. Review Staging Deployment

**Reviewer receives notification:**
- Email notification
- GitHub notification bell
- Slack (if configured)

**To approve:**

1. Go to: `Actions → Select the workflow run`
2. Click "Review deployments"
3. Select environments to approve:
   - ☑ staging
4. Click "Approve and deploy"

**Staging deploys immediately after approval** 

---

### 4. Review Prod Deployment

**After staging succeeds:**

1. Reviewer goes to: `Actions → Select the workflow run`
2. Click "Review deployments"
3. Review:
   -  Staging deployed successfully
   -  Changes look good
   -  Tests passed
4. Select:
   - ☑ prod
5. **Wait 10 minutes** (if wait timer configured)
6. Click "Approve and deploy"

**Prod deploys after approval + wait timer** 

---

## Deployment History

View all deployments per environment:

```
Repository → Environments → [environment] → View deployment history
```

**You'll see:**
-  Successful deployments
-  Failed deployments
- ⏸  Pending approvals
-  Who approved
- ⏱  Duration

---

## Environment Secrets

Scope secrets to specific environments:

### 1. Create Environment Secret

```
Settings → Environments → [environment] → Add secret
```

### 2. Example Secrets

**Dev Environment:**
```
TF_API_TOKEN: [dev-specific token]
AWS_ACCOUNT_ID: 123456789012
```

**Prod Environment:**
```
TF_API_TOKEN: [prod-specific token]
AWS_ACCOUNT_ID: 987654321098
DATADOG_API_KEY: [prod monitoring]
```

**Benefits:**
-  Separate credentials per environment
-  More secure than repository-wide secrets
-  Easier to rotate credentials

---

## Best Practices

###  Do's

1. **Always protect production**
   - Require 2+ approvals
   - Add wait timer
   - Restrict to main branch

2. **Use teams for reviewers**
   - Easier to manage than individual users
   - Automatically includes new team members

3. **Enable self-review prevention**
   - Prevents accidental approvals
   - Enforces peer review

4. **Monitor deployment history**
   - Review regularly
   - Track patterns and issues

5. **Use environment-specific secrets**
   - Separate credentials per environment
   - Rotate regularly

---

###  Don'ts

1. **Don't protect dev**
   - Slows down development
   - Creates unnecessary friction

2. **Don't allow self-review in prod**
   - Security risk
   - Defeats purpose of approvals

3. **Don't skip staging**
   - Always deploy dev → staging → prod
   - Catch issues before production

4. **Don't use same secrets everywhere**
   - Use environment-specific credentials
   - Limit blast radius of compromised secrets

---

## Step-by-Step: First Time Setup

### 1. Create Environments (2 minutes)

```bash
# Go to your GitHub repo
Settings → Environments

# Create three environments:
1. Click "New environment" → Name: "dev" → Configure
2. Click "New environment" → Name: "staging" → Configure  
3. Click "New environment" → Name: "prod" → Configure
```

---

### 2. Configure Dev (30 seconds)

```
Environment: dev
Protection rules: Leave all unchecked
 Save protection rules
```

---

### 3. Configure Staging (1 minute)

```
Environment: staging

☑ Required reviewers
   └─ Add reviewers: @your-team or specific users
   └─ Required reviewers: 1

☑ Allow administrators to bypass

 Save protection rules
```

---

### 4. Configure Prod (2 minutes)

```
Environment: prod

☑ Required reviewers
   └─ Add reviewers: @senior-engineers (or specific users)
   └─ Required reviewers: 2

☑ Prevent self-review

☑ Wait timer: 10 minutes

☑ Deployment branches
   └─ Protected branches: main

☑ Allow administrators to bypass

 Save protection rules
```

---

### 5. Test the Workflow (5 minutes)

```bash
# Make a small change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test deployment workflow"
git push origin main

# Watch in GitHub Actions:
# 1. Dev deploys automatically 
# 2. Staging waits for approval ⏸
# 3. Prod waits for approval ⏸

# Go to Actions → Select workflow → Review deployments
# Approve staging →  Deploys
# Approve prod → ⏰ Waits 10 min →  Deploys
```

---

## Example: Full Production Deployment

### Timeline

```
0:00  Developer pushes to main
0:01  GitHub Actions starts
0:02  Dev environment deploys 
0:02  Staging waits for approval ⏸

[Developer tests in dev, confirms working]

0:15  Reviewer approves staging
0:16  Staging deploys 

[Team tests in staging, confirms working]

0:30  Reviewer approves prod
0:30  Wait timer starts (10 minutes) ⏰
0:40  Prod deploys 

Total time: 40 minutes (safe and controlled)
```

---

## Troubleshooting

### Issue: "Environment not found"

**Cause:** Environment not created in GitHub Settings

**Fix:**
```
Settings → Environments → New environment → Create
```

---

### Issue: "Deployment requires approval but no reviewers"

**Cause:** Protection rules enabled but no reviewers added

**Fix:**
```
Settings → Environments → [environment] → Required reviewers → Add reviewers
```

---

### Issue: "Can't approve my own deployment"

**Cause:** "Prevent self-review" is enabled

**Fix:**
-  This is correct behavior! Ask another team member
-  Or temporarily disable in settings (not recommended)

---

### Issue: "Waiting forever after approval"

**Cause:** Wait timer is configured

**Fix:**
-  Wait for the timer to expire (intended behavior)
-  Or reduce wait timer in environment settings

---

### Issue: "Only admin can deploy to prod"

**Cause:** No reviewers configured or wrong branch

**Fix:**
1. Check: `Settings → Environments → prod → Required reviewers`
2. Add your team as reviewers
3. Check: `Deployment branches` allows your branch

---

## Advanced: Environment-Specific Variables

You can also use environment variables:

```yaml
# In .github/workflows/terraform-apply.yml

environment:
  name: ${{ matrix.environment }}
  url: https://app.terraform.io/app/${{ vars.TF_CLOUD_ORGANIZATION }}/workspaces/infrastructure-${{ matrix.environment }}
```

**Set in GitHub:**
```
Settings → Environments → [environment] → Environment variables

Name: AWS_REGION
Value (dev): us-east-1
Value (prod): us-west-2
```

---

## Summary

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| Auto-deploy |  Yes |  No |  No |
| Required approvals | 0 | 1 | 2 |
| Self-review prevention |  |  |  |
| Wait timer | 0 min | 0 min | 10 min |
| Branch restriction | All | main, release/* | main only |
| Deployment visibility |  |  |  |

---

## Next Steps

1.  [Create environments in GitHub](#step-by-step-first-time-setup)
2.  [Configure protection rules](#environment-protection-rules)
3.  [Test the workflow](#5-test-the-workflow-5-minutes)
4.  [Monitor deployments](#deployment-history)

**Related Documentation:**
- [GitHub Actions Setup](../GITHUB_ACTIONS_SETUP.md)
- [Token Management](TOKEN_MANAGEMENT.md)
- [Troubleshooting](TROUBLESHOOTING.md)

---

## Resources

- [GitHub Docs: Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Docs: Required Reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)
- [GitHub Docs: Deployment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules)
