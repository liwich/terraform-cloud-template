variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name (will be prefixed with environment)"
  type        = string
  default     = "app-storage"
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable S3 lifecycle rules"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (leave empty to use AES256)"
  type        = string
  default     = ""
}

variable "create_dynamodb_table" {
  description = "Create a DynamoDB table"
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name (will be prefixed with environment)"
  type        = string
  default     = "app-data"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_hash_key" {
  description = "DynamoDB hash key (partition key)"
  type        = string
  default     = "id"
}

variable "dynamodb_range_key" {
  description = "DynamoDB range key (sort key)"
  type        = string
  default     = ""
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units (for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units (for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB point-in-time recovery"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
