# Terraform Cloud Token Management

Complete guide for managing Terraform Cloud API tokens securely.

## Token Types

### User Tokens
- **Purpose**: Individual developer access
- **Scope**: All workspaces user has access to
- **Expiration**: Configurable (default: 30 days)
- **Use for**: Local CLI (`terraform login`)
- **Generate at**: https://app.terraform.io/app/settings/tokens

### Team Tokens (Recommended for CI/CD)
- **Purpose**: Automated systems (GitHub Actions, CI/CD)
- **Scope**: Limited to team's workspace access
- **Expiration**: Can be set to never expire
- **Use for**: GitHub Actions, automation
- **Generate at**: Organization Settings → Teams → Team API Token

### Organization Tokens
- **Purpose**: Organization-wide automation
- **Scope**: All workspaces in organization
- **Expiration**: Configurable
- **Requires**: Terraform Cloud Plus or Enterprise
- **Generate at**: Organization Settings → API Tokens

## Setting Up Team Token for GitHub Actions

### Step 1: Create CI/CD Team

1. Go to Terraform Cloud
2. Select your organization
3. Settings → Teams
4. Click **Create a team**
5. Name: `github-actions` or `ci-cd`
6. Click **Create team**

### Step 2: Generate Team Token

1. Settings → Teams → Select your CI/CD team
2. Click **Team API Token** tab
3. Click **Create a team token**
4. **Token Description**: "GitHub Actions CI/CD"
5. **Expiration**: 
   - Select **Never** for permanent token
   - OR select **Custom** and set to 1 year
6. Copy the token (save it securely - you can't view it again!)

### Step 3: Grant Team Workspace Access

For each workspace, grant team access:

1. Go to workspace (e.g., `infrastructure-dev`)
2. Settings → Team Access
3. Click **Add team and permissions**
4. Select your CI/CD team
5. Choose permission level:
   - **Write**: Can plan and apply
   - **Plan**: Can only plan (requires manual approval)
   - **Read**: View only
6. Click **Add team**
7. Repeat for all workspaces (`infrastructure-dev`, `infrastructure-staging`, `infrastructure-prod`)

### Step 4: Add Token to GitHub Secrets

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Find `TF_API_TOKEN` secret (or create new)
4. Click **Update** (or **New repository secret**)
5. Paste the team token
6. Click **Update secret** (or **Add secret**)

### Step 5: Test the Setup

```bash
# Push a small change to test
git add .
git commit -m "Test GitHub Actions with team token"
git push origin main

# Watch in GitHub Actions tab
```

## Token Expiration Settings

### For Team Tokens (GitHub Actions)

**Option 1: Never Expire** (Simplest)
```
 Pros: No maintenance required
 Cons: Security risk if token leaked
 Mitigation: Store in GitHub Secrets, rotate every 90 days
```

**Option 2: 1 Year Expiration** (Balanced)
```
 Pros: Good security/convenience balance
 Cons: Must remember to rotate
 Reminder: Set calendar reminder 2 weeks before expiration
```

**Option 3: 90 Days** (Most Secure)
```
 Pros: Best security practice
 Cons: More frequent rotation needed
 Reminder: Quarterly token rotation
```

### For User Tokens (Local Development)

**Recommended: 30-90 Days**
```bash
# When expired, simply re-authenticate
terraform login

# Your credentials are automatically updated
```

## Token Rotation

### Manual Rotation Process

**For Team Tokens (GitHub Actions)**:

```bash
# Every 90 days (recommended)

# 1. Generate new team token in Terraform Cloud
# 2. Update GitHub Secret
#    GitHub → Settings → Secrets → Actions → TF_API_TOKEN → Update
# 3. Test by triggering a workflow
#    git commit --allow-empty -m "Test new token"
#    git push
# 4. Delete old token in Terraform Cloud
#    Settings → Teams → [Team] → Team API Token → Delete
```

**For User Tokens (Local CLI)**:

```bash
# When token expires or every 90 days
terraform login

# Automatically updates ~/.terraform.d/credentials.tfrc.json
```

### Rotation Calendar

Set up reminders:

```
Every 90 Days:
- [ ] Generate new team token
- [ ] Update GitHub Secret
- [ ] Test GitHub Actions
- [ ] Delete old token
- [ ] Update this date: _______
```

## Monitoring Token Usage

### In Terraform Cloud

View token usage and last used:

1. Settings → Teams → [Team Name] → Team API Token
2. See **Last Used** timestamp
3. If not used recently, consider revoking

### In GitHub

View Secret last updated:

1. Settings → Secrets and variables → Actions
2. See **Updated** timestamp for each secret

## Emergency: Token Compromised

If a token is compromised:

### Immediate Actions

```bash
# 1. Delete compromised token immediately
Terraform Cloud → Settings → Teams → Delete token

# 2. Generate new token
Create new team token with same permissions

# 3. Update GitHub Secret
GitHub → Settings → Secrets → Update TF_API_TOKEN

# 4. Check for unauthorized runs
Terraform Cloud → Workspaces → Check run history

# 5. Review team access
Settings → Teams → Review all members
```

### Prevention

```
 Store tokens in GitHub Secrets only
 Never commit tokens to Git
 Use .gitignore for local credentials
 Enable GitHub Secret scanning
 Use team tokens (not user tokens) for automation
 Set appropriate workspace permissions
```

## Alternative: VCS-Driven Workflow (No Token Needed!)

For GitHub-based workflows, consider VCS integration:

**Advantages**:
-  No API tokens to manage
-  OAuth-based authentication
-  Automatic token rotation by GitHub/Terraform Cloud
-  Simpler for teams

**Setup**: See [VCS Integration Guide](VCS_INTEGRATION.md)

**Trade-off**: Less flexible than GitHub Actions

## Token Storage Locations

### GitHub Actions (Encrypted Secrets)
```
Location: Repository → Settings → Secrets → Actions → TF_API_TOKEN
Security: Encrypted at rest, decrypted only during workflow runs
Access: Only workflow runs, not visible to users
```

### Local Development (User Token)
```
Location: ~/.terraform.d/credentials.tfrc.json
Security: Plain text file (OS-level security)
Format:
{
  "credentials": {
    "app.terraform.io": {
      "token": "xxxxxxxx"
    }
  }
}
```

### Never Store In
```
 Git repository (even in .env files)
 Public documentation
 Slack/chat messages
 Email
 Plain text files in shared locations
```

## Best Practices Summary

### For GitHub Actions (CI/CD)

```yaml
Token Type: Team Token
Expiration: Never (or 1 year)
Storage: GitHub Secrets
Rotation: Every 90 days
Permissions: Write (or Plan if requiring approval)
Scope: Specific workspaces only
```

### For Local Development

```yaml
Token Type: User Token
Expiration: 30-90 days
Storage: ~/.terraform.d/credentials.tfrc.json
Rotation: On expiration (automatic via terraform login)
Permissions: Based on user's org access
Scope: All accessible workspaces
```

### For Production Workspaces

```yaml
Token Type: Team Token (separate from dev)
Expiration: 90 days
Additional: Require manual approval for applies
Team Access: Limited to specific production team
Audit: Regular review of access logs
```

## Troubleshooting

### "401 Unauthorized" in GitHub Actions

**Cause**: Token expired or invalid

**Solution**:
```bash
# 1. Generate new team token
# 2. Update GitHub Secret: TF_API_TOKEN
# 3. Re-run workflow
```

### Token Works Locally But Not in GitHub Actions

**Cause**: Using user token instead of team token

**Solution**:
```bash
# 1. Create team token (not user token)
# 2. Grant team access to workspaces
# 3. Update GitHub Secret with team token
```

### Can't Find Team Token Option

**Cause**: Not enough organization permissions

**Solution**:
```bash
# Ask organization owner to:
# 1. Grant you "Manage Teams" permission
# OR
# 2. Create token and share securely
```

## Automation Scripts

### Token Expiration Reminder

Add to your calendar or use this GitHub Action:

```yaml
# .github/workflows/token-reminder.yml
name: Token Rotation Reminder

on:
  schedule:
    # Run on the 1st of every month
    - cron: '0 0 1 * *'
  workflow_dispatch:

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - name: Check token age
        run: |
          echo "⏰ Monthly reminder: Check TF_API_TOKEN expiration"
          echo "Last rotated: [Update this date]"
          echo "Action: https://github.com/${{ github.repository }}/settings/secrets/actions"
```

## Additional Resources

- [Terraform Cloud Token Documentation](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [VCS Integration Guide](VCS_INTEGRATION.md) - Alternative to tokens
- [Troubleshooting Guide](TROUBLESHOOTING.md#terraform-cloud-authentication)

## Quick Reference

| Scenario | Token Type | Expiration | Storage | Rotation |
|----------|-----------|------------|---------|----------|
| **Local Dev** | User | 30-90 days | `~/.terraform.d/` | Auto on expire |
| **GitHub Actions** | Team | Never/1 year | GitHub Secrets | Manual 90 days |
| **Production CI/CD** | Team | 90 days | GitHub Secrets | Manual 90 days |
| **Testing** | User | 7-30 days | `~/.terraform.d/` | Frequent |
| **VCS-Driven** | None | N/A | OAuth | Automatic |
