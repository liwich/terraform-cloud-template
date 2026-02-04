# Environment Configuration

## Enabling/Disabling Environments

By default, only the `dev` environment is enabled for deployments. You can enable `staging` and `prod` when you're ready.

### How to Enable Staging and Prod

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
3. Click **New repository variable**
4. Create a variable:
   - **Name**: `ENABLED_ENVIRONMENTS`
   - **Value**: Choose one:
     - `dev` (default, dev only)
     - `dev staging` (enable staging)
     - `dev staging prod` (enable all environments)

### Examples

**Enable only dev** (default, no variable needed):
```
ENABLED_ENVIRONMENTS = dev
```

**Enable dev and staging**:
```
ENABLED_ENVIRONMENTS = dev staging
```

**Enable all environments**:
```
ENABLED_ENVIRONMENTS = dev staging prod
```

### How It Works

The GitHub Actions workflows check this variable before deploying:
- If an environment is **not** in the list, it will be **skipped** even if files changed
- If an environment **is** in the list, it will be deployed when its files change
- If the variable is not set, only `dev` is deployed (safe default)

### Workflow Behavior

**Path triggers** remain the same - workflows trigger on changes to:
- `environments/**` (any environment directory)
- `modules/**` (shared modules)

But the **actual deployment** is filtered by `ENABLED_ENVIRONMENTS`.

### Example Scenarios

**Scenario 1**: You change `modules/vpc/main.tf`
- Without variable (default): Only `dev` deploys
- With `ENABLED_ENVIRONMENTS=dev staging`: Both `dev` and `staging` deploy
- With `ENABLED_ENVIRONMENTS=dev`: Only `dev` deploys

**Scenario 2**: You change `environments/prod/main.tf`
- Without variable (default): Nothing deploys (prod not enabled)
- With `ENABLED_ENVIRONMENTS=dev staging prod`: `prod` deploys

### Quick Start Timeline

1. **Day 1**: Start with `dev` only (no variable needed)
2. **Week 2**: Add staging → Set `ENABLED_ENVIRONMENTS=dev staging`
3. **Production ready**: Enable prod → Set `ENABLED_ENVIRONMENTS=dev staging prod`

This approach lets you gradually roll out environments without modifying workflows or code! 
