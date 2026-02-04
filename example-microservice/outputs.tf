output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.app.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

# Information about consumed shared infrastructure
output "shared_vpc_id" {
  description = "VPC ID from shared infrastructure"
  value       = local.vpc_id
}

output "shared_private_subnets" {
  description = "Private subnet IDs from shared infrastructure"
  value       = local.private_subnet_ids
}

output "shared_availability_zones" {
  description = "Availability zones from shared infrastructure"
  value       = local.availability_zones
}
