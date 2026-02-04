# S3 Bucket for Application Storage
resource "aws_s3_bucket" "app" {
  bucket = "${var.environment}-${var.bucket_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.bucket_name}"
    }
  )
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "delete-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket Logging (optional)
resource "aws_s3_bucket" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${var.environment}-${var.bucket_name}-logs"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.bucket_name}-logs"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "app" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.app.id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "log/"
}

# DynamoDB Table for Application Data
resource "aws_dynamodb_table" "app" {
  count          = var.create_dynamodb_table ? 1 : 0
  name           = "${var.environment}-${var.dynamodb_table_name}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = var.dynamodb_hash_key
  range_key      = var.dynamodb_range_key
  
  # For PROVISIONED billing mode
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.dynamodb_range_key != "" ? [1] : []
    content {
      name = var.dynamodb_range_key
      type = "S"
    }
  }

  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id != "" ? var.kms_key_id : null
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.dynamodb_table_name}"
    }
  )
}
