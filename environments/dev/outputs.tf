# VPC outputs for consumption by microservices
# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# output "vpc_cidr_block" {
#   description = "The CIDR block of the VPC"
#   value       = module.vpc.vpc_cidr_block
# }

# output "private_subnet_ids" {
#   description = "List of private subnet IDs"
#   value       = module.vpc.private_subnet_ids
# }

# output "public_subnet_ids" {
#   description = "List of public subnet IDs"
#   value       = module.vpc.public_subnet_ids
# }

# output "private_subnet_cidrs" {
#   description = "List of private subnet CIDR blocks"
#   value       = module.vpc.private_subnet_cidrs
# }

# output "public_subnet_cidrs" {
#   description = "List of public subnet CIDR blocks"
#   value       = module.vpc.public_subnet_cidrs
# }

# output "nat_gateway_ids" {
#   description = "List of NAT Gateway IDs"
#   value       = module.vpc.nat_gateway_ids
# }

# output "internet_gateway_id" {
#   description = "The ID of the Internet Gateway"
#   value       = module.vpc.internet_gateway_id
# }

# output "availability_zones" {
#   description = "List of availability zones used"
#   value       = var.availability_zones
# }

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "aws_region" {
  description = "The AWS region"
  value       = var.aws_region
}
