# CLI Usage Guide

Complete guide for using Terraform CLI with this template and Terraform Cloud.

## Understanding Execution Modes

Terraform Cloud has two execution modes:

### Remote Execution (Default)
- **Terraform runs in Terraform Cloud**, not on your machine
- Your CLI uploads the configuration and streams the output
- State is managed in Terraform Cloud
- Requires uploading full directory structure

### Local Execution
- **Terraform runs on your machine**
- Only state is stored in Terraform Cloud
- Useful for development and debugging
- No directory structure upload issues

## Running Terraform Commands

### With Remote Execution (Default)

**Run from project root with `-chdir`**:

```bash
# Always from project root
cd /path/to/terraform-cloud-template

# Use -chdir to specify environment
terraform -chdir=environments/dev init
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply

# For other environments
terraform -chdir=environments/staging plan
terraform -chdir=environments/prod plan
```

**Why `-chdir`?**
- Uploads entire project structure to Terraform Cloud
- Ensures `modules/` directory is accessible
- Recommended for remote execution

### With Local Execution

**Run from environment directory**:

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

**Requires**: Workspace execution mode set to "Local" in Terraform Cloud UI.

## Switching Execution Modes

### Remote → Local (For Development)

**Via Terraform Cloud UI**:
1. Go to https://app.terraform.io
2. Select workspace (e.g., `infrastructure-dev`)
3. Settings → General Settings
4. Execution Mode: Select "Local"
5. Save

**Benefits**:
- Faster development cycles
- Run from environment directories
- Easier debugging
- Still uses remote state

### Local → Remote (For Production)

**Via Terraform Cloud UI**:
1. Workspace → Settings → General Settings
2. Execution Mode: Select "Remote"
3. Save

**Benefits**:
- Team collaboration
- Centralized execution logs
- Policy enforcement (Sentinel)
- Cost estimation

## Common Workflows

### Development Workflow (Local Execution)

```bash
# 1. Set workspace to Local execution mode (one-time)
# (Done in Terraform Cloud UI)

# 2. Work normally from environment directory
cd environments/dev

# 3. Make changes
vi main.tf

# 4. Test changes
terraform plan

# 5. Apply when ready
terraform apply

# 6. Iterate quickly
```

**Pros**: Fast iteration, familiar workflow
**Cons**: Runs only on your machine

### Team/Production Workflow (Remote Execution)

```bash
# Always work from project root
cd /path/to/terraform-cloud-template

# Make changes
vi environments/dev/main.tf

# Run from root with -chdir
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

**Pros**: Runs in cloud, team visibility, audit logs
**Cons**: Requires `-chdir` flag

### Recommended: GitHub Actions (Best of Both)

Push to GitHub → GitHub Actions runs Terraform via API:
- No local execution needed
- Centralized logs
- PR reviews before apply
- No `-chdir` complexity

## Command Reference

### Initialize Workspace

```bash
# Remote execution (from root)
terraform -chdir=environments/dev init

# Local execution (from environment)
cd environments/dev
terraform init

# Force reconfiguration
terraform init -reconfigure

# Migrate state
terraform init -migrate-state
```

### Plan Changes

```bash
# Remote execution
terraform -chdir=environments/dev plan

# Local execution
cd environments/dev
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Target specific resource
terraform plan -target=module.vpc
```

### Apply Changes

```bash
# Remote execution
terraform -chdir=environments/dev apply

# Local execution
cd environments/dev
terraform apply

# Auto-approve (careful!)
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan
```

### View Outputs

```bash
# Remote execution
terraform -chdir=environments/dev output

# Local execution
cd environments/dev
terraform output

# Specific output
terraform output vpc_id

# JSON format
terraform output -json
```

### Destroy Resources

```bash
# Remote execution
terraform -chdir=environments/dev destroy

# Local execution
cd environments/dev
terraform destroy

# Target specific resource
terraform destroy -target=module.vpc
```

### State Management

```bash
# List resources
terraform state list

# Show specific resource
terraform state show module.vpc.aws_vpc.main

# Remove from state (doesn't destroy)
terraform state rm module.vpc.aws_vpc.main

# Move resource in state
terraform state mv module.old module.new

# Pull remote state
terraform state pull

# Refresh state
terraform refresh
```

### Workspace Commands

```bash
# Note: These are Terraform CLI workspaces, different from Terraform Cloud workspaces
# Not commonly used with Terraform Cloud

terraform workspace list
terraform workspace select dev
terraform workspace new staging
```

## Troubleshooting

### "Unreadable module directory"

**Problem**: Running remote execution from environment directory

**Solution**: Run from project root with `-chdir`:
```bash
cd /path/to/terraform-cloud-template
terraform -chdir=environments/dev apply
```

### "Backend configuration changed"

**Problem**: Switched between local and remote backends

**Solution**: Reinitialize with migration:
```bash
terraform init -migrate-state
```

### "Unauthorized"

**Problem**: Not authenticated with Terraform Cloud

**Solution**:
```bash
terraform login
```

### Slow execution

**Problem**: Remote execution has network latency

**Solution**: Switch to local execution for development:
- Workspace → Settings → Execution Mode → Local

### Can't see detailed logs

**Problem**: Remote execution streams high-level output

**Solution**: View detailed logs in Terraform Cloud UI:
- Click the run URL in CLI output
- Full logs available in browser

## Best Practices

### ✅ Do

**Development**:
- Use local execution mode
- Run from environment directories
- Iterate quickly with `plan` before `apply`

**Production**:
- Use remote execution
- Run from project root with `-chdir`
- Use GitHub Actions for automation
- Require approvals in Terraform Cloud UI

**Always**:
- Run `terraform plan` before `apply`
- Review changes carefully
- Use `-target` for surgical changes
- Keep state in Terraform Cloud

### ❌ Don't

- Don't commit local state files
- Don't run production changes from your laptop
- Don't use `-auto-approve` in production
- Don't edit state files manually
- Don't share credentials in code

## Integration with CI/CD

### GitHub Actions (Included)

Workflows already configured:
- Runs from repository root
- No `-chdir` issues
- Automatic on PR/merge
- See `.github/workflows/`

### Manual Runs

For one-off changes or testing:
```bash
# From project root
terraform -chdir=environments/dev apply
```

### Local Development, Remote Deployment

1. **Develop locally** (Local execution mode)
2. **Test changes** (`terraform plan`)
3. **Commit to Git** (`git commit`)
4. **Push to GitHub** (triggers Actions)
5. **GitHub Actions** deploys remotely

Best of both worlds!

## Quick Reference

| Task | Remote Execution | Local Execution |
|------|------------------|-----------------|
| **Where to run** | Project root | Environment dir |
| **Init** | `terraform -chdir=environments/dev init` | `cd environments/dev && terraform init` |
| **Plan** | `terraform -chdir=environments/dev plan` | `terraform plan` |
| **Apply** | `terraform -chdir=environments/dev apply` | `terraform apply` |
| **Output** | `terraform -chdir=environments/dev output` | `terraform output` |
| **Execution** | Terraform Cloud | Your machine |
| **Speed** | Slower (network) | Faster (local) |
| **Team visibility** | ✅ Yes | ❌ No |
| **Audit logs** | ✅ Yes | ⚠️ Limited |

## Summary

**Choose your workflow**:

1. **Quick local testing**: Local execution mode + run from env dirs
2. **Team collaboration**: Remote execution + `-chdir` from root
3. **Production deployments**: GitHub Actions (recommended)

**Most common setup**:
- Dev workspace: Local execution (fast iteration)
- Staging workspace: Remote execution (test automation)
- Prod workspace: Remote execution via GitHub Actions

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for initial configuration.
