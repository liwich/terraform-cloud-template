output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions to assume"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.github_actions.name
}

output "setup_instructions" {
  description = "Instructions for using this role in GitHub Actions"
  value       = <<-EOT
  
  ✅ OIDC Setup Complete!
  
  Add this to your GitHub Actions workflow:
  
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${aws_iam_role.github_actions.arn}
      aws-region: ${var.aws_region}
  
  No secrets needed! GitHub Actions will authenticate automatically.
  EOT
}
