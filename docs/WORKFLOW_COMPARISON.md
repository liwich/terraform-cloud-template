# CI/CD Workflow Comparison

Quick reference guide to help you choose between GitHub Actions (API-driven) and VCS-driven workflows.

## Quick Decision Matrix

```
┌─────────────────────────────────────────────────────────────┐
│                    Choose GitHub Actions If:                │
├─────────────────────────────────────────────────────────────┤
│  You need custom validation steps before Terraform        │
│  You want maximum flexibility in your CI/CD pipeline      │
│  You're managing multiple tools beyond Terraform          │
│  You need complex approval workflows                      │
│  You want faster initial setup                            │
│  Your team is familiar with GitHub Actions                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Choose VCS-Driven Workflow If:            │
├─────────────────────────────────────────────────────────────┤
│  You prefer HashiCorp's recommended approach              │
│  You want simplest possible team onboarding               │
│  You need native Terraform Cloud features (Sentinel)      │
│  You have large distributed teams (50+ people)            │
│  Enterprise governance is your top priority               │
│  You prefer fewer moving parts in your automation         │
└─────────────────────────────────────────────────────────────┘
```

## Visual Comparison

### GitHub Actions (API-Driven) - Default

```
┌──────────┐    ┌───────────────┐    ┌──────────────┐    ┌────────┐
│Developer │───▶│ GitHub Repo   │───▶│GitHub Actions│───▶│TF Cloud│
└──────────┘    │  (main)       │    │  Workflow    │    │  API   │
                └───────────────┘    └──────────────┘    └────────┘
                                             │
                                             ▼
                                     ┌──────────────┐
                                     │ Custom Steps:│
                                     │ • Lint       │
                                     │ • Test       │
                                     │ • Security   │
                                     │ • Validate   │
                                     └──────────────┘
```

**Flow**: Push → GitHub Actions → Custom Logic → Terraform Cloud API → Execute

### VCS-Driven Workflow

```
┌──────────┐    ┌───────────────┐    ┌──────────────┐
│Developer │───▶│ GitHub Repo   │───▶│  TF Cloud    │
└──────────┘    │  (main)       │    │  (Direct)    │
                └───────────────┘    └──────────────┘
                                             │
                                             ▼
                                     ┌──────────────┐
                                     │  Auto-Plan   │
                                     │  Review      │
                                     │  Apply       │
                                     └──────────────┘
```

**Flow**: Push → Terraform Cloud Detects → Auto-Plan → Review → Apply

## Feature Comparison

| Feature | GitHub Actions | VCS-Driven |
|---------|----------------|------------|
| **Setup Time** | 5 minutes | 15 minutes |
| **Setup Complexity** | Low (add secret) | Medium (OAuth) |
| **Customization** |  Unlimited |  Limited |
| **Pre-Terraform Steps** |  Yes (lint, test, etc.) |  No |
| **Terraform Execution** | Remote (TF Cloud) | Remote (TF Cloud) |
| **State Management** | Remote (TF Cloud) | Remote (TF Cloud) |
| **PR Plans** |  Automatic |  Automatic |
| **Plan Comments** |  GitHub PR |  GitHub PR |
| **Run Queue** | Manual |  Built-in |
| **Multi-Workspace** | Custom logic |  Native |
| **Approval Process** | GitHub + TF Cloud | TF Cloud UI |
| **Audit Trail** | GitHub + TF Cloud | Git + TF Cloud |
| **Team Permissions** | GitHub + TF Cloud | TF Cloud |
| **Cost** | Free (GitHub tier) | Free (TF tier) |
| **Debugging** | GitHub Actions logs | TF Cloud logs |
| **Vendor Lock-in** | Low | Medium |

## Real-World Scenarios

### Scenario 1: Startup (5-10 developers)

**Recommendation**: GitHub Actions 

**Reasoning**:
- Faster setup, less overhead
- Team likely familiar with GitHub Actions
- Need flexibility as requirements evolve
- May integrate other tools later

### Scenario 2: Enterprise (100+ developers)

**Recommendation**: VCS-Driven 

**Reasoning**:
- Simpler onboarding at scale
- HashiCorp recommended for enterprise
- Native run queuing and workspace management
- Better for compliance and audit requirements
- Integration with Sentinel policies (if using)

### Scenario 3: Regulated Industry (finance, healthcare)

**Recommendation**: Either (based on preference)

**Both provide**:
- Complete audit trail
- Change approval workflows
- State encryption
- No secrets in code

**VCS-Driven edge**: Native Terraform Cloud features may be preferred by auditors

### Scenario 4: Multi-Cloud / Multi-Tool

**Recommendation**: GitHub Actions 

**Reasoning**:
- Need to orchestrate Terraform + other tools
- Custom validation steps required
- Different workflows for different providers
- Maximum flexibility needed

## Cost Analysis

### GitHub Actions

```
Free Tier: 2,000 minutes/month
Typical Usage: ~50 minutes/month (10 deployments)
Cost: $0

Additional costs:
- GitHub: Free for public repos, $4/user for private
- Terraform Cloud: Free tier (5 users)
```

### VCS-Driven

```
Terraform Cloud: Free tier (5 users)
VCS Provider: Free (GitHub.com)

No additional CI/CD costs
Runs executed entirely in Terraform Cloud
```

**Both are free for small teams!**

## Migration Path

### From GitHub Actions → VCS-Driven

**Effort**: 2-4 hours
**Risk**: Low (can test in dev first)

Steps:
1. Set up OAuth connection
2. Configure workspaces
3. Test in dev environment
4. Disable GitHub Actions
5. Roll out to other environments

### From VCS-Driven → GitHub Actions

**Effort**: 1-2 hours
**Risk**: Low (workflows included)

Steps:
1. Add `TF_API_TOKEN` to GitHub Secrets
2. Disconnect VCS from workspaces
3. Test in dev environment
4. Roll out to other environments

**Both directions are straightforward migrations.**

## Hybrid Approach

You can use **both simultaneously** for different environments:

```
Development: CLI-driven (fast iteration)
     ↓
Staging: GitHub Actions (testing automation)
     ↓
Production: VCS-Driven (maximum governance)
```

**Example**:
- `infrastructure-dev`: GitHub Actions (flexible testing)
- `infrastructure-staging`: GitHub Actions (pre-prod testing)
- `infrastructure-prod`: VCS-driven (governance + simplicity)

## Common Misconceptions

###  "VCS-driven is more secure"

**Reality**: Both are equally secure. Security depends on:
- Branch protection rules
- Approval processes
- Secret management
- Team permissions

###  "GitHub Actions is not production-ready"

**Reality**: GitHub Actions is used by millions of production deployments daily. The Terraform Cloud API is the official way to interact programmatically.

###  "VCS-driven is the only 'proper' way"

**Reality**: HashiCorp supports and documents all three workflows (VCS, API, CLI). Choose based on your needs.

###  "You must choose one forever"

**Reality**: Migration between approaches is straightforward and low-risk.

## Recommendations by Organization Size

### Individuals & Small Teams (1-5 people)

**Recommended**: GitHub Actions
- Faster to set up
- More flexibility for experimentation
- Easier to customize as you learn

### Medium Teams (5-50 people)

**Recommended**: Either (preference-based)
- GitHub Actions: If team is GitHub-savvy
- VCS-driven: If prefer HashiCorp native approach

### Large Teams (50+ people)

**Recommended**: VCS-Driven
- Simpler onboarding at scale
- Native workspace management
- Better for distributed teams

### Enterprise (100+ people)

**Recommended**: VCS-Driven
- Enterprise features (Sentinel)
- Audit and compliance requirements
- HashiCorp support and best practices

## Summary

**There is no "wrong" choice.** Both approaches are:
-  Production-ready
-  Secure
-  Scalable
-  Well-documented
-  Supported by HashiCorp

**Choose based on**:
- Team preferences
- Existing tooling
- Flexibility requirements
- Organization size

**This template defaults to GitHub Actions** for maximum flexibility and ease of use, but **VCS-driven is one simple configuration change away**.

See [VCS Integration Guide](VCS_INTEGRATION.md) for setup instructions.
