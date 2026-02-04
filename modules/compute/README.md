# Compute Module

This module creates EC2 compute resources with the following features:

- Auto Scaling Group with Launch Template
- Security Groups with HTTP/HTTPS access
- IAM Role with SSM access for management
- Auto-scaling policies based on CPU utilization
- IMDSv2 enforcement for better security

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"

  environment         = "dev"
  app_name           = "web-app"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  instance_type    = "t3.micro"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  
  tags = {
    Project = "my-project"
  }
}
```

## Features

- **Auto Scaling**: Automatically scales based on CPU utilization
- **Security**: IMDSv2 required, SSM access for secure management (no SSH needed)
- **Monitoring**: CloudWatch detailed monitoring enabled

## Inputs

See `variables.tf` for all available inputs.

## Outputs

See `outputs.tf` for all available outputs.
