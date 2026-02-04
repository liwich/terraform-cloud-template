# VCS-Driven Workflow Integration

This guide explains how to set up VCS-driven workflow with Terraform Cloud for enterprise environments that prefer HashiCorp's recommended approach.

## Table of Contents

1. [Overview](#overview)
2. [When to Use VCS-Driven vs GitHub Actions](#when-to-use-vcs-driven-vs-github-actions)
3. [Prerequisites](#prerequisites)
4. [Setup VCS Connection](#setup-vcs-connection)
5. [Configure Workspaces](#configure-workspaces)
6. [Workflow](#workflow)
7. [Best Practices](#best-practices)
8. [Comparison with GitHub Actions](#comparison-with-github-actions)
9. [Migration Path](#migration-path)

## Overview

### VCS-Driven Workflow

With VCS-driven workflow, Terraform Cloud directly connects to your version control system (GitHub, GitLab, Bitbucket, Azure DevOps) and automatically triggers runs when you push changes.

```
Developer → Push to Branch → Terraform Cloud detects change → Auto-plan → Review → Merge → Auto-apply
```

**Key Benefit**: Native integration with Terraform Cloud, recommended by HashiCorp for production environments.

### This Template's Default (GitHub Actions)

The template uses GitHub Actions to trigger Terraform Cloud via API:

```
Developer → Push to Branch → GitHub Actions → Terraform Cloud API → Remote execution
```

**Key Benefit**: More flexible, easier initial setup, works with any Git provider.

## When to Use VCS-Driven vs GitHub Actions

### Use VCS-Driven Workflow When:

 **Enterprise governance is critical**
- Need native Terraform Cloud run triggers
- Want simplest possible setup for teams
- Prefer HashiCorp's recommended approach
- Using Terraform Enterprise features (Sentinel policies, etc.)

 **Team structure favors it**
- Large teams with many contributors
- Need workspace-level access control
- Want automatic run queuing

 **Compliance requirements**
- Need to demonstrate VCS as single source of truth
- Auditors prefer native integrations
- Regulatory requirements for change management

### Use GitHub Actions (Default) When:

 **Flexibility is important**
- Need custom validation steps
- Want to run tests before Terraform
- Need to integrate with other tools
- Require complex approval workflows

 **Multi-cloud or hybrid environments**
- Managing multiple providers beyond Terraform Cloud
- Using multiple automation tools
- Need different workflows per environment

 **Development speed matters**
- Faster iteration cycles
- More control over when runs happen
- Easier debugging of CI/CD pipeline

## Prerequisites

1.  Terraform Cloud organization
2.  GitHub repository (or GitLab, Bitbucket, Azure DevOps)
3.  Admin access to both
4.  This template already set up

## Setup VCS Connection

### Step 1: Connect VCS Provider to Terraform Cloud

#### For GitHub:

1. **Go to Terraform Cloud**:
   - Organization Settings → Version Control → Providers

2. **Add VCS Provider**:
   - Click "Connect a VCS provider"
   - Select "GitHub" → "GitHub.com"

3. **Authorize OAuth**:
   - Follow GitHub authorization flow
   - Grant access to your organization/repositories
   - Copy the **OAuth Token ID** (you'll need this)

4. **Verify Connection**:
   - Should see "Connected" status
   - Note the OAuth Token ID format: `ot-xxxxxxxxxxxxx`

#### For GitHub Enterprise, GitLab, Bitbucket:

See [Terraform Cloud VCS Documentation](https://developer.hashicorp.com/terraform/cloud-docs/vcs) for provider-specific instructions.

### Step 2: Update Setup Script (Optional)

The setup script can configure VCS automatically. Set environment variables:

```bash
export TFC_TOKEN="your-token"
export TFC_ORGANIZATION="your-org"
export TFC_PROJECT="infrastructure"

# VCS Configuration
export VCS_REPO="your-github-org/terraform-cloud-template"
export VCS_OAUTH_TOKEN_ID="ot-xxxxxxxxxxxxx"  # From Step 1

# Run setup
./scripts/setup.sh
```

Or run interactively and provide VCS details when prompted.

### Step 3: Configure Workspaces Manually

If you've already created workspaces, update them:

#### For Each Workspace (dev, staging, prod):

1. **Go to Workspace Settings**:
   - Terraform Cloud → Select workspace → Settings

2. **Version Control**:
   - Click "Connect to version control"
   - Select your connected VCS provider
   - Choose repository: `your-org/terraform-cloud-template`

3. **Configure Settings**:
   ```
   VCS Branch: main
   Working Directory: environments/dev  (or staging, prod)
   Automatic Run Triggering:  Enabled
   Automatic speculative plans:  Enabled (for PRs)
   ```

4. **Trigger Patterns** (Advanced):
   ```
   Trigger prefixes (optional):
   - environments/dev/**
   - modules/**
   ```
   
   This ensures the workspace only triggers when relevant files change.

5. **Apply Settings**:
   - Auto-apply: Enable for dev, disable for staging/prod
   - Requires approval: Enable for prod

6. **Save**

Repeat for all three environments (dev, staging, prod).

## Workflow

### Development Workflow

#### 1. Create Feature Branch

```bash
git checkout -b feature/add-s3-bucket
```

#### 2. Make Infrastructure Changes

```bash
# Edit Terraform files
vi environments/dev/main.tf

# Commit changes
git add environments/dev/main.tf
git commit -m "Add S3 bucket for application data"
git push origin feature/add-s3-bucket
```

#### 3. Create Pull Request

**Terraform Cloud automatically**:
- Detects the push
- Runs speculative plan (doesn't affect state)
- Posts plan as PR comment (if configured)
- Shows status check on PR

#### 4. Review Plan

**In Terraform Cloud UI**:
- Navigate to workspace → Runs
- Review the speculative plan
- Check resources to be created/modified/destroyed

**In GitHub PR**:
- See plan summary in checks
- Click details to view full plan in Terraform Cloud

#### 5. Approve and Merge

```bash
# After approval
git checkout main
git merge feature/add-s3-bucket
git push origin main
```

#### 6. Automatic Apply

**Terraform Cloud automatically**:
- Detects merge to main
- Runs plan
- If auto-apply enabled: automatically applies
- If auto-apply disabled: waits for approval in UI

### Production Workflow

For production workspaces, add manual approval:

1. **Merge triggers plan**
2. **Team reviews in Terraform Cloud**
3. **Designated approver clicks "Confirm & Apply"**
4. **Changes are applied**

## Best Practices

### 1. Branch Protection Rules

Configure in GitHub repository settings:

```yaml
Branch: main
Rules:
   Require pull request reviews (minimum 2)
   Require status checks to pass
     - Terraform Cloud - infrastructure-dev
   Require branches to be up to date
   Require linear history
   Include administrators
```

### 2. Workspace Strategy

```
Repository: terraform-cloud-template
├── Workspace: infrastructure-dev
│   Working Directory: environments/dev
│   Auto-apply:  Yes
│   Branch: main
│
├── Workspace: infrastructure-staging  
│   Working Directory: environments/staging
│   Auto-apply:  No (manual approval)
│   Branch: main
│
└── Workspace: infrastructure-prod
    Working Directory: environments/prod
    Auto-apply:  No (manual approval)
    Branch: main
    Requires: 2 approvers in Terraform Cloud
```

### 3. Notification Setup

Configure in Workspace Settings → Notifications:

**Slack Integration**:
```
Events to notify:
- Run needs attention (manual approval required)
- Run errored
- Run failed policy check
```

**Email Notifications**:
```
Send to: infrastructure-team@company.com
Events: All runs, errors, and policy failures
```

### 4. Run Triggers (Advanced)

For dependent workspaces (e.g., applications consuming shared infrastructure):

```
Workspace: infrastructure-dev
Settings → Run Triggers
Add: app-backend-dev

Result: When infrastructure-dev applies successfully, 
        app-backend-dev automatically plans
```

### 5. Sentinel Policies (Enterprise)

Enforce governance with policy as code:

```python
# Example: Require specific tags
import "tfplan/v2" as tfplan

mandatory_tags = ["Environment", "Owner", "CostCenter"]

main = rule {
  all tfplan.resource_changes as _, rc {
    all mandatory_tags as tag {
      rc.change.after.tags contains tag
    }
  }
}
```

### 6. Working Directory Best Practices

```
 Good: Separate working directories per environment
Workspace: infrastructure-dev
Working Dir: environments/dev

 Good: Module-specific workspaces
Workspace: shared-vpc
Working Dir: modules/vpc

 Bad: Multiple workspaces in same directory
Causes conflicts and confusion
```

## Comparison with GitHub Actions

| Feature | VCS-Driven | GitHub Actions |
|---------|------------|----------------|
| **Setup Complexity** | Medium (OAuth) | Low (just token) |
| **Native Integration** |  Yes | Via API |
| **Custom Validation** |  Limited |  Unlimited |
| **Multi-provider** | Terraform only |  Any tool |
| **Speculative Plans** |  Automatic |  Via workflow |
| **Run Management** | TFC UI | GitHub UI |
| **Queue Management** |  Built-in | Manual |
| **Cost** | Free (TFC tier) | Free (GitHub tier) |
| **Learning Curve** | Low | Medium |
| **Enterprise Features** |  Full access | Via API |
| **Debugging** | TFC logs | GitHub logs |
| **Flexibility** | Low |  High |

## Migration Path

### From GitHub Actions to VCS-Driven

If you're currently using the template's GitHub Actions and want to migrate:

#### 1. Set Up VCS Connection

Follow steps above to connect Terraform Cloud to GitHub.

#### 2. Update Workspaces

Configure each workspace with VCS settings.

#### 3. Disable GitHub Actions (Optional)

```bash
# Rename workflows to disable
mv .github/workflows/terraform-plan.yml .github/workflows/terraform-plan.yml.disabled
mv .github/workflows/terraform-apply.yml .github/workflows/terraform-apply.yml.disabled
```

Or delete them:
```bash
rm .github/workflows/terraform-*.yml
```

#### 4. Test Workflow

```bash
# Create test branch
git checkout -b test-vcs-integration

# Make small change
echo "# VCS test" >> environments/dev/main.tf
git commit -am "Test VCS integration"
git push origin test-vcs-integration

# Create PR and verify Terraform Cloud runs automatically
```

#### 5. Update Documentation

Update your team's runbooks to reflect the new workflow.

### From VCS-Driven to GitHub Actions

If you prefer more control:

#### 1. Disconnect VCS

In each workspace:
- Settings → Version Control
- Click "Disconnect from version control"

#### 2. Enable GitHub Actions

The template already includes workflows. Just add the secret:
- GitHub → Settings → Secrets → Actions
- Add `TF_API_TOKEN`

#### 3. Test

Push changes and verify GitHub Actions trigger runs.

## Troubleshooting

### VCS Not Triggering Runs

**Check**:
1.  Workspace connected to correct repository
2.  Working directory matches pushed files
3.  Branch matches (usually `main`)
4.  OAuth token has repository access
5.  File paths trigger the workspace

**Solution**:
```bash
# Verify working directory
# Workspace: infrastructure-dev
# Working Directory: environments/dev
# Push should affect: environments/dev/**

# Check trigger patterns in workspace settings
```

### Speculative Plans Not Showing in PRs

**Check**:
1.  "Automatic speculative plans" enabled in workspace
2.  GitHub PR from same repository (not fork)
3.  Terraform Cloud has PR comment permissions

**Solution**:
- Workspace Settings → VCS
- Verify GitHub App has PR write permissions

### Multiple Workspaces Triggering

**Problem**: Pushing to `modules/` triggers all workspaces

**Solution**: Configure trigger patterns:
```
Workspace: infrastructure-dev
Settings → VCS → Trigger Patterns
Add:
  - environments/dev/**
  - modules/**

Workspace: infrastructure-prod  
Add:
  - environments/prod/**
  - modules/**
```

### OAuth Connection Expired

**Symptom**: "Unable to connect to VCS"

**Solution**:
1. Organization Settings → Version Control
2. Find your VCS provider
3. Click "Reconnect"
4. Reauthorize OAuth

## Security Considerations

### 1. Repository Access

```
 Good: Grant Terraform Cloud access to specific repositories only
 Bad: Grant access to all repositories
```

### 2. Branch Protection

```
 Good: Protect main branch, require reviews
 Bad: Allow direct pushes to main
```

### 3. Secret Management

```
 Good: Secrets in Terraform Cloud workspace variables
 Bad: Secrets in Git repository (even encrypted)
```

### 4. Approval Requirements

```
 Production: Require manual approval + 2 reviewers
 Staging: Require manual approval + 1 reviewer  
 Dev: Auto-apply acceptable for development
```

## Advanced Patterns

### 1. Monorepo with Multiple Workspaces

```
repo/
├── infrastructure/
│   ├── network/          → Workspace: network-prod
│   ├── compute/          → Workspace: compute-prod
│   └── databases/        → Workspace: databases-prod
```

Each workspace configured with its specific working directory.

### 2. Environment Branches (Alternative Pattern)

```
Branches:
├── main → prod workspace
├── staging → staging workspace
└── develop → dev workspace

Workspace: infrastructure-prod
VCS Branch: main

Workspace: infrastructure-staging
VCS Branch: staging
```

**Note**: This pattern is less common, but useful for organizations with strict promotion processes.

### 3. Module Development Workflow

```
Workspace: module-testing
Working Directory: modules/vpc
Purpose: Test module changes before using in environments
```

## Additional Resources

- [Terraform Cloud VCS Documentation](https://developer.hashicorp.com/terraform/cloud-docs/vcs)
- [GitHub OAuth Setup](https://developer.hashicorp.com/terraform/cloud-docs/vcs/github)
- [GitLab OAuth Setup](https://developer.hashicorp.com/terraform/cloud-docs/vcs/gitlab)
- [Speculative Plans](https://developer.hashicorp.com/terraform/cloud-docs/run/ui#speculative-plans)
- [Run Triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-triggers)

## Summary

**VCS-driven workflow is recommended when**:
- Enterprise governance is priority
- Team prefers HashiCorp's native approach  
- Simpler setup outweighs flexibility

**GitHub Actions (default) is recommended when**:
- Need custom validation steps
- Want maximum flexibility
- Managing complex multi-tool pipelines

Both approaches are production-ready and secure. Choose based on your organization's needs and preferences.
