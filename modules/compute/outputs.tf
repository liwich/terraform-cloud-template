output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.app.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.app.name
}
