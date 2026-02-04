# Storage Module

This module creates AWS storage resources with security best practices:

## S3 Bucket Features
- Server-side encryption (AES256 or KMS)
- Versioning enabled
- Public access blocked
- Lifecycle rules for cost optimization
- Optional access logging
- Automatic cleanup of incomplete multipart uploads

## DynamoDB Features (Optional)
- On-demand or provisioned billing
- Encryption at rest
- Point-in-time recovery (optional)
- Flexible key schema

## Usage

### S3 Only

```hcl
module "storage" {
  source = "../../modules/storage"

  environment            = "dev"
  bucket_name           = "app-storage"
  enable_versioning     = true
  enable_lifecycle_rules = true
  
  tags = {
    Project = "my-project"
  }
}
```

### S3 + DynamoDB

```hcl
module "storage" {
  source = "../../modules/storage"

  environment         = "dev"
  bucket_name        = "app-storage"
  
  create_dynamodb_table = true
  dynamodb_table_name   = "app-data"
  dynamodb_billing_mode = "PAY_PER_REQUEST"
  dynamodb_hash_key     = "userId"
  dynamodb_range_key    = "timestamp"
  
  tags = {
    Project = "my-project"
  }
}
```

## Security

- All S3 buckets have public access blocked by default
- Encryption at rest enabled for all resources
- Lifecycle rules to automatically transition old data to cheaper storage

## Inputs

See `variables.tf` for all available inputs.

## Outputs

See `outputs.tf` for all available outputs.
