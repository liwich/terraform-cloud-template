# Example Microservice - Consuming Shared Infrastructure

This is an example microservice repository that demonstrates how to consume shared infrastructure (VPC, subnets, etc.) from the main `terraform-cloud-template` using Terraform remote state.

## Overview

This example shows the pattern for deploying application-specific infrastructure that uses shared resources:

- **Shared Infrastructure** (from main template):
  - VPC
  - Subnets (public/private)
  - NAT Gateways
  - Internet Gateway

- **This Microservice** (application-specific):
  - ECS Cluster
  - ECS Service (Fargate)
  - Application Security Group
  - CloudWatch Logs

## Prerequisites

1. ✅ Shared infrastructure deployed (from terraform-cloud-template)
2. ✅ Terraform Cloud account
3. ✅ AWS credentials configured
4. ✅ Remote state sharing enabled on shared infrastructure workspace

## Quick Start

### 1. Create Workspace in Terraform Cloud

```bash
# Using the Terraform Cloud UI or API
# Create workspace: "my-app-dev" (or your preferred name)
```

### 2. Configure Backend

Update `backend.tf` with your Terraform Cloud organization:

```hcl
terraform {
  cloud {
    organization = "YOUR-ORG-NAME"  # Change this
    
    workspaces {
      name = "my-app-dev"  # Change this
    }
  }
}
```

### 3. Set Variables

Copy and customize the example:

```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

Update:
```hcl
tfc_organization = "YOUR-ORG-NAME"
environment      = "dev"
app_name         = "my-app"
container_image  = "nginx:latest"  # Your Docker image
```

### 4. Enable Remote State Sharing

In the **shared infrastructure workspace**:

1. Go to Terraform Cloud
2. Select workspace: `infrastructure-dev`
3. Settings → General Settings
4. Under "Remote state sharing":
   - Select "Share with specific workspaces"
   - Add `my-app-dev` (this workspace)
5. Save

### 5. Deploy

```bash
# Initialize
terraform init

# Review what will be created
terraform plan

# Deploy
terraform apply
```

## Architecture

```
┌─────────────────────────────────────────────┐
│ infrastructure-dev workspace (shared)       │
│  - VPC (10.0.0.0/16)                       │
│  - Private Subnets                          │
│  - Public Subnets                           │
│  - NAT Gateways                             │
│                                             │
│  Outputs:                                   │
│  ├─ vpc_id                                  │
│  ├─ private_subnet_ids                      │
│  ├─ public_subnet_ids                       │
│  └─ vpc_cidr_block                          │
└─────────────────┬───────────────────────────┘
                  │
                  │ terraform_remote_state
                  │
┌─────────────────▼───────────────────────────┐
│ my-app-dev workspace (this application)     │
│                                             │
│  Reads from shared infrastructure:          │
│  ├─ VPC ID                                  │
│  └─ Private Subnet IDs                      │
│                                             │
│  Creates:                                   │
│  ├─ Security Group (in shared VPC)          │
│  ├─ ECS Cluster                             │
│  ├─ ECS Task Definition                     │
│  ├─ ECS Service (in private subnets)        │
│  └─ CloudWatch Log Group                    │
└─────────────────────────────────────────────┘
```

## What This Example Demonstrates

### 1. Remote State Data Source

```hcl
data "terraform_remote_state" "shared_infra" {
  backend = "remote"
  
  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "infrastructure-${var.environment}"
    }
  }
}
```

### 2. Accessing Shared Resources

```hcl
locals {
  vpc_id             = data.terraform_remote_state.shared_infra.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids
}

resource "aws_security_group" "app" {
  vpc_id = local.vpc_id  # From shared infrastructure
  # ...
}
```

### 3. Deploying to Shared Network

```hcl
resource "aws_ecs_service" "app" {
  # ...
  network_configuration {
    subnets = local.private_subnet_ids  # From shared infrastructure
    # ...
  }
}
```

## Files Overview

| File | Purpose |
|------|---------|
| `backend.tf` | Terraform Cloud backend configuration |
| `data.tf` | Remote state data sources and locals |
| `main.tf` | Application resources (ECS, security groups) |
| `variables.tf` | Input variables |
| `outputs.tf` | Output values |
| `terraform.tfvars.example` | Example variable values |
| `.gitignore` | Prevent committing secrets |

## Deployment Patterns

### Pattern 1: Single Microservice

```
infrastructure → my-app
```

Deploy one app per workspace, consuming shared infrastructure.

### Pattern 2: Multiple Microservices

```
infrastructure
     ├→ backend-api
     ├→ frontend-web
     └→ worker-jobs
```

Each microservice has its own workspace, all consuming the same shared infrastructure.

### Pattern 3: Multi-Environment

```
infrastructure-dev → my-app-dev
infrastructure-staging → my-app-staging  
infrastructure-prod → my-app-prod
```

Environment-specific deployments with matching infrastructure.

## Customization

### Use Your Own Container

Update `terraform.tfvars`:

```hcl
container_image = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
```

### Add Environment Variables

Update task definition in `main.tf`:

```hcl
container_definitions = jsonencode([{
  name  = var.app_name
  image = var.container_image
  environment = [
    {
      name  = "DATABASE_URL"
      value = "postgresql://..."
    }
  ]
}])
```

### Scale Services

Update `terraform.tfvars`:

```hcl
desired_count = 3  # Run 3 tasks
cpu          = "512"
memory       = "1024"
```

### Add Load Balancer

Extend `main.tf`:

```hcl
resource "aws_lb" "app" {
  name               = "${var.app_name}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_ecs_service" "app" {
  # ...
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = 80
  }
}
```

## Best Practices

### 1. Version Control

- ✅ Commit all `.tf` files
- ❌ Never commit `terraform.tfvars` (has secrets)
- ✅ Commit `terraform.tfvars.example`

### 2. State Isolation

- Each microservice has its own workspace
- Independent deployment and rollback
- No impact on other services

### 3. Environment Parity

- Use same configuration across environments
- Vary only through variables
- Test in dev before prod

### 4. Resource Naming

```hcl
resource "aws_ecs_cluster" "app" {
  name = "${var.app_name}-${var.environment}"  # e.g., my-app-dev
}
```

### 5. Documentation

Document dependencies in your README:
- Which shared infrastructure is required
- Which outputs are needed
- Order of deployment

## Troubleshooting

### Error: "No stored state found"

**Solution**: Ensure shared infrastructure is deployed first:

```bash
cd ../terraform-cloud-template/environments/dev
terraform apply
```

### Error: "Access denied to workspace"

**Solution**: Enable remote state sharing (see step 4 above)

### Error: "Output not found: vpc_id"

**Solution**: Check shared infrastructure has the output:

```bash
cd ../terraform-cloud-template/environments/dev
terraform output
```

### Container Won't Start

**Check**:
1. Container image exists and is accessible
2. Task execution role has ECR permissions
3. CloudWatch logs for error messages
4. Security groups allow necessary traffic

## Clean Up

To destroy resources:

```bash
terraform destroy
```

**Note**: This only destroys resources in this workspace. Shared infrastructure remains intact.

## Next Steps

1. Customize for your application
2. Add monitoring and alerting
3. Configure auto-scaling
4. Add CI/CD pipeline
5. Implement secrets management

## Additional Examples

See `docs/CONSUMING_INFRASTRUCTURE.md` in the main repository for:
- More complex scenarios
- Database integration
- Multi-tier applications
- Advanced patterns

## Support

For issues or questions:
- Review [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
- Check [Consuming Infrastructure Guide](../docs/CONSUMING_INFRASTRUCTURE.md)
- Open an issue on the main repository

---

**Remember**: This is a template. Customize it for your specific application needs!
