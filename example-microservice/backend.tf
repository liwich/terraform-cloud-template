terraform {
  cloud {
    organization = "YOUR-ORG-NAME"  # TODO: Replace with your Terraform Cloud organization
    
    workspaces {
      name = "my-app-dev"  # TODO: Replace with your workspace name
    }
  }
  
  required_version = "~> 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
