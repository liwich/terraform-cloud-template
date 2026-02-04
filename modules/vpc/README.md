# VPC Module

This module creates a production-ready AWS VPC with the following features:

- Multi-AZ deployment
- Public and private subnets
- Internet Gateway for public subnets
- NAT Gateway(s) for private subnets (configurable: single or per-AZ)
- VPC Flow Logs (optional)
- Proper route tables and associations

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  environment          = "dev"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true  # Use false for production
  
  tags = {
    Project = "my-project"
  }
}
```

## Cost Optimization

For development environments, set `single_nat_gateway = true` to use only one NAT Gateway across all availability zones, reducing costs from ~$100/month to ~$33/month.

For production environments, use `single_nat_gateway = false` for high availability.

## Inputs

See `variables.tf` for all available inputs.

## Outputs

See `outputs.tf` for all available outputs. These outputs are designed to be consumed by other modules or via remote state.
