variable "aws_region" {
  description = "AWS region for the OIDC provider"
  type        = string
  default     = "us-west-2"
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "GitHubActionsTerraformRole"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "enable_environment_restrictions" {
  description = "Enable environment-specific restrictions"
  type        = bool
  default     = false
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}
