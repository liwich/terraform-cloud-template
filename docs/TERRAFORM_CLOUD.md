# Terraform Cloud Concepts and Best Practices

This guide explains Terraform Cloud concepts and how they're used in this template.

## Table of Contents

1. [What is Terraform Cloud?](#what-is-terraform-cloud)
2. [Key Concepts](#key-concepts)
3. [Why Use Terraform Cloud?](#why-use-terraform-cloud)
4. [Remote State Management](#remote-state-management)
5. [Workspaces vs Local Terraform](#workspaces-vs-local-terraform)
6. [Collaboration Features](#collaboration-features)
7. [Cost Estimation](#cost-estimation)
8. [Sentinel Policies](#sentinel-policies)
9. [Best Practices](#best-practices)

## What is Terraform Cloud?

Terraform Cloud is HashiCorp's managed service that provides:
- Remote state storage and locking
- Collaborative infrastructure management
- Private module registry
- Policy enforcement (Sentinel)
- Cost estimation
- Run history and audit logs

**Free Tier**: Up to 5 users, unlimited workspaces

## Key Concepts

### Organization

Top-level entity that contains everything:
- Teams and users
- Projects and workspaces
- Settings and policies

**Example**: `my-company`

### Project

Logical grouping of related workspaces:
- Organizes workspaces by application or team
- Simplifies permissions management
- Available in free tier

**Example**: `infrastructure`, `app-backend`, `app-frontend`

### Workspace

Individual environment with:
- Separate state file
- Variables and environment variables
- Run history
- Settings and permissions

**Example**: `infrastructure-dev`, `infrastructure-prod`

### State File

JSON file containing:
- Current infrastructure resources
- Resource relationships
- Output values
- Metadata

**Storage**: Encrypted at rest in Terraform Cloud

### Runs

Execution of `terraform plan` and `terraform apply`:
- Queued and processed in order
- Full audit trail
- Can be triggered manually, via VCS, or API

## Why Use Terraform Cloud?

### 1. State Management

**Problem**: Local state files are:
- Not shared between team members
- Prone to conflicts
- Risk of loss
- Contain sensitive data

**Solution**: Terraform Cloud:
- Centrally stores state
- Automatically locks state during operations
- Encrypts state at rest and in transit
- Provides versioning and rollback

### 2. Collaboration

**Team Benefits**:
- Everyone works from same state
- State locking prevents conflicts
- Run history shows who did what
- Comments and notifications
- Role-based access control

### 3. Security

**Enhanced Security**:
- State stored encrypted
- Variables can be marked sensitive
- Fine-grained permissions
- Audit logs
- No credentials on local machines

### 4. Automation

**CI/CD Integration**:
- API-driven workflows
- VCS integration
- Automatic planning on PRs
- Webhook notifications

## Remote State Management

### State Locking

Prevents concurrent modifications:

```
User A starts apply
  ↓
State locked
  ↓
User B tries to apply → Blocked "State locked by User A"
  ↓
User A finishes
  ↓
State unlocked
  ↓
User B can now proceed
```

### State Sharing

Share outputs between workspaces:

```hcl
# In shared infrastructure workspace
output "vpc_id" {
  value = aws_vpc.main.id
}

# In consuming workspace
data "terraform_remote_state" "infra" {
  backend = "remote"
  config = {
    organization = "my-org"
    workspaces = {
      name = "infrastructure-dev"
    }
  }
}

# Use the output
resource "aws_security_group" "app" {
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
}
```

**Permissions Required**: Workspace must allow remote state sharing

### State Versioning

Every state change is versioned:
- View historical states
- Rollback if needed
- Compare versions
- Downloadable for backup

## Workspaces vs Local Terraform

### Local Terraform Workspaces

```bash
terraform workspace list
terraform workspace new dev
terraform workspace select prod
```

**Local workspaces**:
- Share same configuration
- Separate state files locally
- Good for single developer

### Terraform Cloud Workspaces

**Cloud workspaces**:
- Separate state in cloud
- Independent variables
- Different working directories
- Team collaboration
- More like separate "projects"

**This template**: Each environment is a separate workspace

## Collaboration Features

### 1. Run History

Track all infrastructure changes:
- Who made the change
- When it occurred
- What was changed
- Plan output
- Apply results

### 2. State Locking

Automatic prevention of conflicts:
- Lock acquired automatically
- Visible who has lock
- Can force-unlock if needed (careful!)

### 3. Speculative Plans

Plan without locking state:
- Used for PRs
- Shows potential changes
- Doesn't block others
- GitHub Actions workflows use this

### 4. Team Management

Role-based access:

**Roles**:
- `Read`: View runs and state
- `Plan`: Create plans
- `Write`: Approve and apply
- `Admin`: Manage workspace settings

### 5. Notifications

Get notified on:
- Run completion
- Errors
- Approvals needed
- Via email, Slack, webhooks

## Cost Estimation

Terraform Cloud estimates AWS costs:

```
Plan: 3 to add, 0 to change, 0 to destroy

Cost Estimate:
  + aws_nat_gateway.main
    $32.85/month

  + aws_ec2_instance.app
    $8.47/month

Total: $41.32/month
```

**Features**:
- Pre-apply cost visibility
- Compare cost changes
- Monthly estimates
- Supports AWS, Azure, GCP

**Limitation**: Free tier includes cost estimation

## Sentinel Policies

Policy-as-code for governance (Terraform Cloud Plus/Enterprise):

```python
# Example: Enforce tagging
import "tfplan/v2" as tfplan

mandatory_tags = ["Environment", "Owner", "Project"]

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.after.tags contains all mandatory_tags
  }
}
```

**Use Cases**:
- Enforce tagging standards
- Prevent large instance types
- Require encryption
- Limit regions
- Cost controls

**Note**: This template doesn't include Sentinel (requires paid plan)

## Best Practices

### 1. Workspace Organization

✅ **Do**:
- One workspace per environment
- Consistent naming convention
- Group related workspaces in projects
- Use descriptive names

❌ **Don't**:
- Mix environments in one workspace
- Use generic names like "workspace-1"

### 2. Variable Management

✅ **Do**:
- Mark secrets as sensitive
- Use environment variables for credentials
- Document variable purposes
- Set appropriate defaults

❌ **Don't**:
- Commit secrets to version control
- Hard-code credentials
- Use same variables across all environments

### 3. State Management

✅ **Do**:
- Enable remote state sharing selectively
- Use outputs for cross-workspace references
- Version control your configurations
- Regular state backups (export)

❌ **Don't**:
- Share state globally
- Manually edit state files
- Delete workspaces without backup

### 4. Team Collaboration

✅ **Do**:
- Use least-privilege access
- Require approvals for production
- Document changes in commits
- Use pull requests for reviews

❌ **Don't**:
- Give everyone admin access
- Skip peer reviews
- Apply directly to production

### 5. CI/CD Integration

✅ **Do**:
- Use API-driven workflows
- Automate testing and validation
- Plan on every PR
- Require successful plan before merge

❌ **Don't**:
- Auto-apply to production without review
- Skip validation steps
- Ignore failed plans

## Terraform Cloud Tiers

### Free

- 5 users
- Unlimited workspaces
- State management
- Remote execution
- Cost estimation
- VCS integration

**Perfect for**: Small teams, side projects, this template

### Plus ($20/user/month)

- Everything in Free
- Sentinel policies
- Audit logging
- SSO
- Run triggers

**Good for**: Companies needing compliance

### Enterprise

- Everything in Plus
- Self-hosted option
- Advanced security
- Clustering
- 24/7 support

**Good for**: Large enterprises

## Migrating to Terraform Cloud

From local state:

```bash
# 1. Configure backend
# Edit backend.tf to use Terraform Cloud

# 2. Reinitialize
terraform init -migrate-state

# 3. Confirm migration
# State is now in Terraform Cloud
```

## Monitoring and Observability

### Run Notifications

Configure in workspace settings:
- Slack integration
- Email alerts
- Webhook endpoints
- Microsoft Teams

### Audit Logs

Track all actions:
- User logins
- Configuration changes
- State modifications
- Permission updates

Available in Plus tier and above.

## Workflow Options

Terraform Cloud supports three workflow types:

### 1. VCS-Driven Workflow

Terraform Cloud connects directly to your Git repository:

```
Git Push → Terraform Cloud detects → Auto-plan → Review → Merge → Auto-apply
```

**Best for**: Enterprise teams, simpler setup, native integration

**See**: [VCS Integration Guide](VCS_INTEGRATION.md)

### 2. API-Driven Workflow (This Template's Default)

GitHub Actions triggers Terraform Cloud via API:

```
Git Push → GitHub Actions → Terraform Cloud API → Remote execution
```

**Best for**: Flexibility, custom validation, multi-tool pipelines

**Setup**: Included by default in this template

### 3. CLI-Driven Workflow

Local Terraform CLI triggers remote execution:

```
Local CLI → Terraform Cloud → Remote execution
```

**Best for**: Development, testing, manual operations

**Usage**: Run `terraform plan/apply` locally after `terraform login`

### Enterprise Recommendation

For **enterprise production environments**, consider:
- **VCS-driven** for production workspaces (tighter governance)
- **API-driven** (GitHub Actions) for flexibility and control
- **CLI-driven** for development and testing

This template uses **API-driven** (via GitHub Actions) as the default for maximum flexibility, but VCS-driven is a simple migration path for enterprises. See [VCS Integration Guide](VCS_INTEGRATION.md) for setup instructions.

## Additional Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Cloud API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [VCS Integration](https://developer.hashicorp.com/terraform/cloud-docs/vcs)
- [State Locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [Remote State Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
