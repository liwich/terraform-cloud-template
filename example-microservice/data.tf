# Read outputs from the shared infrastructure workspace
data "terraform_remote_state" "shared_infra" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "infrastructure-${var.environment}" # e.g., infrastructure-dev
    }
  }
}

# Store shared infrastructure outputs in locals for easy access
locals {
  # Network configuration from shared infrastructure
  vpc_id             = data.terraform_remote_state.shared_infra.outputs.vpc_id
  vpc_cidr_block     = data.terraform_remote_state.shared_infra.outputs.vpc_cidr_block
  private_subnet_ids = data.terraform_remote_state.shared_infra.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.shared_infra.outputs.public_subnet_ids
  availability_zones = data.terraform_remote_state.shared_infra.outputs.availability_zones

  # Resource naming
  name_prefix = "${var.app_name}-${var.environment}"

  # Tags
  common_tags = merge(
    var.tags,
    {
      Application = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Workspace   = "${var.app_name}-${var.environment}"
    }
  )
}
