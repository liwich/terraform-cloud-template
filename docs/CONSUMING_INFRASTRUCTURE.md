# Consuming Shared Infrastructure

This guide explains how to consume shared infrastructure (VPC, subnets, etc.) from other Terraform projects using remote state.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Setting Up Remote State Access](#setting-up-remote-state-access)
4. [Example Microservice Setup](#example-microservice-setup)
5. [Best Practices](#best-practices)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)

## Overview

### The Problem

You have shared infrastructure (VPC, subnets, security groups) and multiple applications/microservices that need to use them. How do they access this information?

### The Solution

**Terraform Remote State**: Query outputs from the shared infrastructure workspace.

```
┌─────────────────────────────────┐
│ Shared Infrastructure Workspace │
│  - VPC                          │
│  - Subnets                      │
│  - Security Groups              │
│                                 │
│  Outputs:                       │
│  - vpc_id                       │
│  - private_subnet_ids           │
└─────────────────┬───────────────┘
                  │
                  │ terraform_remote_state
                  │
┌─────────────────▼───────────────┐
│ Microservice Workspace          │
│  - ECS Service                  │
│  - Security Group               │
│  - Uses VPC from remote state   │
└─────────────────────────────────┘
```

## Prerequisites

1. Shared infrastructure workspace deployed
2. Terraform Cloud account with access to both workspaces
3. Remote state sharing enabled on shared infrastructure workspace

## Setting Up Remote State Access

### Step 1: Enable State Sharing

In the shared infrastructure workspace:

1. Go to Terraform Cloud workspace settings
2. Navigate to "General Settings"
3. Under "Remote state sharing", select:
   - "Share with specific workspaces"
   - Add workspace names that need access (e.g., `app-backend-dev`)

### Step 2: Verify Permissions

Ensure your Terraform Cloud token has:
- Read access to shared infrastructure workspace
- Write access to your microservice workspace

### Step 3: Configure Data Source

In your microservice Terraform code:

```hcl
# data.tf
data "terraform_remote_state" "shared_infra" {
  backend = "remote"
  
  config = {
    organization = "my-organization"
    workspaces = {
      name = "infrastructure-dev"
    }
  }
}

# Store commonly used values in locals
locals {
  vpc_id              = data.terraform_remote_state.shared_infra.outputs.vpc_id
  private_subnet_ids  = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids
  public_subnet_ids   = data.terraform_remote_state.shared_infra.outputs.public_subnet_ids
  vpc_cidr_block      = data.terraform_remote_state.shared_infra.outputs.vpc_cidr_block
}
```

## Example Microservice Setup

See the [`example-microservice/`](../../example-microservice) directory for a complete working example.

### Directory Structure

```
my-microservice/
├── backend.tf              # Terraform Cloud backend
├── data.tf                 # Remote state data sources
├── main.tf                 # Microservice resources
├── variables.tf            # Variables
├── outputs.tf              # Outputs
└── terraform.tfvars.example
```

### Complete Example: ECS Service

**backend.tf**:
```hcl
terraform {
  cloud {
    organization = "my-organization"
    
    workspaces {
      name = "my-app-dev"
    }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**data.tf**:
```hcl
# Read shared infrastructure outputs
data "terraform_remote_state" "shared_infra" {
  backend = "remote"
  
  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "infrastructure-${var.environment}"
    }
  }
}

# Convenient access to shared resources
locals {
  vpc_id             = data.terraform_remote_state.shared_infra.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.shared_infra.outputs.public_subnet_ids
}
```

**main.tf**:
```hcl
provider "aws" {
  region = var.aws_region
}

# Security group using shared VPC
resource "aws_security_group" "app" {
  name        = "${var.app_name}-${var.environment}"
  description = "Security group for ${var.app_name}"
  vpc_id      = local.vpc_id  # From shared infrastructure!
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]  # From shared infrastructure!
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "app" {
  name = "${var.app_name}-${var.environment}"
}

# ECS Service using shared subnets
resource "aws_ecs_service" "app" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  
  network_configuration {
    subnets         = local.private_subnet_ids  # From shared infrastructure!
    security_groups = [aws_security_group.app.id]
  }
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  
  container_definitions = jsonencode([{
    name  = var.app_name
    image = var.container_image
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
  }])
}
```

**variables.tf**:
```hcl
variable "tfc_organization" {
  description = "Terraform Cloud organization"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "container_image" {
  description = "Docker image for the application"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}
```

## Best Practices

### 1. Design Shared Infrastructure Outputs

**Good outputs** (in shared infrastructure):

```hcl
# Specific and descriptive
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for application deployment"
  value       = module.vpc.private_subnet_ids
}

output "database_security_group_id" {
  description = "Security group ID for database access"
  value       = module.security.database_sg_id
}
```

**Bad outputs**:

```hcl
# Too vague
output "subnets" {
  value = aws_subnet.all[*].id  # Which subnets? Public? Private?
}

# Missing description
output "sg" {
  value = aws_security_group.app.id
}
```

### 2. Use Locals for Readability

```hcl
# Good: Clear and reusable
locals {
  vpc_id            = data.terraform_remote_state.shared_infra.outputs.vpc_id
  private_subnets   = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids
}

resource "aws_instance" "app" {
  subnet_id = local.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.app.id]
}

# Bad: Repeated long references
resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids[0]
  # ...
}
```

### 3. Environment-Specific Workspaces

```hcl
# Use variable to select correct workspace
data "terraform_remote_state" "shared_infra" {
  backend = "remote"
  
  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "infrastructure-${var.environment}"  # dev, staging, or prod
    }
  }
}
```

### 4. Document Dependencies

In your README:

```markdown
## Prerequisites

This application requires the shared infrastructure to be deployed first:

1. Deploy `infrastructure-dev` workspace
2. Verify outputs are available:
   - vpc_id
   - private_subnet_ids
   - public_subnet_ids
3. Enable remote state sharing for this workspace
```

### 5. Handle Missing Outputs Gracefully

```hcl
# Use try() for optional outputs
locals {
  vpc_id = data.terraform_remote_state.shared_infra.outputs.vpc_id
  
  # Optional output with fallback
  database_sg_id = try(
    data.terraform_remote_state.shared_infra.outputs.database_security_group_id,
    null
  )
}

# Use count to conditionally create resources
resource "aws_security_group_rule" "database_access" {
  count = local.database_sg_id != null ? 1 : 0
  
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = local.database_sg_id
  security_group_id        = aws_security_group.app.id
}
```

## Common Patterns

### Pattern 1: Application Deployment

Shared infrastructure provides:
- VPC and subnets
- Shared security groups (e.g., database access)
- Load balancer (optional)

Application consumes:
- Deploys to private subnets
- References shared security groups
- Attaches to shared load balancer

### Pattern 2: Multi-Tier Application

```
infrastructure workspace → VPC, subnets, base security groups
           ↓
database workspace → RDS in private subnets
           ↓
backend workspace → ECS service, references database SG
           ↓
frontend workspace → CloudFront + S3, references backend endpoint
```

### Pattern 3: Multiple Teams

```
platform-team workspace → Core infrastructure
           ↓
     ┌─────┴─────┐
     ↓           ↓
team-a workspace  team-b workspace
(their apps)      (their apps)
```

## Troubleshooting

### Error: "No stored state was found for the given workspace"

**Cause**: The shared infrastructure workspace hasn't been applied yet.

**Solution**:
1. Deploy shared infrastructure first
2. Verify the workspace name is correct
3. Check you have access to the workspace

### Error: "Error loading state: access denied"

**Cause**: Remote state sharing not enabled or insufficient permissions.

**Solution**:
1. In shared workspace: Settings → General → Remote state sharing
2. Add your microservice workspace name
3. Verify your Terraform Cloud token has read access

### Error: "Unsupported attribute: This object does not have an attribute named 'vpc_id'"

**Cause**: The output doesn't exist in the shared infrastructure.

**Solution**:
1. Check the shared infrastructure outputs: `terraform output`
2. Add missing outputs to `outputs.tf`
3. Apply the shared infrastructure
4. Update your data source reference

### Workspace Name Mismatch

```hcl
#  Wrong: Hardcoded workspace name
data "terraform_remote_state" "shared_infra" {
  config = {
    workspaces = {
      name = "infrastructure-dev"  # What about staging/prod?
    }
  }
}

#  Correct: Dynamic workspace selection
data "terraform_remote_state" "shared_infra" {
  config = {
    workspaces = {
      name = "infrastructure-${var.environment}"
    }
  }
}
```

### Circular Dependencies

**Problem**: Workspace A depends on B, which depends on A.

**Solution**: Redesign dependencies:
- Shared infrastructure should not depend on applications
- Create intermediate "shared services" workspace if needed
- Use discovery mechanisms (tags, service discovery) instead of direct references

## Security Considerations

### 1. Least Privilege Access

Only share state with workspaces that need it:

```
 Share infrastructure-dev state with app-backend-dev
 Share infrastructure-prod state with app-backend-prod
 Don't share prod state with dev workspaces
```

### 2. Sensitive Outputs

Be careful with sensitive data in outputs:

```hcl
#  Bad: Exposing secrets
output "database_password" {
  value = aws_db_instance.main.password
}

#  Good: Only expose references
output "database_endpoint" {
  value = aws_db_instance.main.endpoint
}

#  Better: Use secrets manager
output "database_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
```

### 3. Review Access Regularly

Audit who has access to shared state:
- Review workspace permissions quarterly
- Remove unused workspaces from share list
- Use team-based access instead of user tokens

## Next Steps

1. Review the [example-microservice](../../example-microservice) directory
2. Create your first microservice workspace
3. Enable remote state sharing
4. Deploy and test
5. Document your infrastructure dependencies

## Additional Resources

- [Terraform Remote State Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [Terraform Cloud Workspace Permissions](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#permissions)
- [Organizing Terraform Projects](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
