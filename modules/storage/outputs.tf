output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.app.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.app.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.app.bucket_regional_domain_name
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = var.create_dynamodb_table ? aws_dynamodb_table.app[0].id : null
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = var.create_dynamodb_table ? aws_dynamodb_table.app[0].arn : null
}
