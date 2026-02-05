# S3 Bucket Terraform Module

A comprehensive Terraform module for creating and managing AWS S3 buckets with security best practices and extensive configuration options.

## Features

- ✅ Server-side encryption (AES256 or KMS)
- ✅ Versioning control
- ✅ Lifecycle policies
- ✅ CORS configuration
- ✅ Static website hosting
- ✅ Bucket policies and IAM controls
- ✅ Cross-region replication
- ✅ Object lock (WORM)
- ✅ Transfer acceleration
- ✅ Public access blocking
- ✅ S3 access logging for audit trails

## Usage

### Basic Example

```hcl
module "s3_bucket" {
  source = "./s3"

  bucket_name = "my-application-bucket"
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Static Website Hosting

```hcl
module "website_bucket" {
  source = "./s3"

  bucket_name             = "my-static-website"
  website_enabled         = true
  website_index_document  = "index.html"
  website_error_document  = "404.html"
  
  # Allow public access for website
  restrict_public_buckets = false
  s3_object_ownership     = "ObjectWriter"
  acl                     = "public-read"
  
  tags = {
    Purpose = "Static Website"
  }
}
```

### Encrypted Bucket with Lifecycle Rules

```hcl
module "secure_bucket" {
  source = "./s3"

  bucket_name                  = "secure-data-bucket"
  versioning_enabled           = true
  sse_algorithm                = "aws:kms"
  kms_master_key_arn           = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  allow_encrypted_uploads_only = true
  allow_ssl_requests_only      = true
  
  lifecycle_configuration_rules = [
    {
      enabled = true
      id      = "archive-old-versions"
      abort_incomplete_multipart_upload_days = 7
      
      filter_and = null
      
      expiration = null
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
      
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "GLACIER"
        }
      ]
    }
  ]
  
  tags = {
    Compliance = "required"
  }
}
```

### Using Naming Conventions for Multi-Environment

```hcl
# Development environment
module "dev_bucket" {
  source = "./s3"

  bucket_name                       = "myapp-data"
  naming_prefix                     = "dev"
  use_naming_convention_for_bucket  = true
  
  # Creates bucket: dev-myapp-data
  # IAM resources: dev-myapp-data-replication-*
  
  tags = {
    Environment = "development"
  }
}

# Production environment
module "prod_bucket" {
  source = "./s3"

  bucket_name                       = "myapp-data"
  naming_prefix                     = "prod"
  use_naming_convention_for_bucket  = true
  
  # Creates bucket: prod-myapp-data
  # IAM resources: prod-myapp-data-replication-*
  
  tags = {
    Environment = "production"
  }
}

# Using suffix instead
module "bucket_with_suffix" {
  source = "./s3"

  bucket_name                       = "myapp-data"
  naming_suffix                     = "us-east-1"
  use_naming_convention_for_bucket  = true
  
  # Creates bucket: myapp-data-us-east-1
  # IAM resources: myapp-data-us-east-1-replication-*
  
  tags = {
    Region = "us-east-1"
  }
}

# Using both prefix and suffix
module "bucket_full_naming" {
  source = "./s3"

  bucket_name                       = "myapp-data"
  naming_prefix                     = "prod"
  naming_suffix                     = "us-west-2"
  use_naming_convention_for_bucket  = true
  
  # Creates bucket: prod-myapp-data-us-west-2
  # IAM resources: prod-myapp-data-us-west-2-replication-*
}
```

### Bucket with Access Logging

```hcl
# First, create a bucket to store logs
module "log_bucket" {
  source = "./s3"

  bucket_name = "my-app-logs"
  
  # Logs bucket should have restricted access
  restrict_public_buckets = true
  versioning_enabled      = true
  
  tags = {
    Purpose = "Access Logs"
  }
}

# Then create your main bucket with logging enabled
module "app_bucket" {
  source = "./s3"

  bucket_name = "my-application-data"
  
  enable_bucket_logging  = true
  logging_target_bucket  = module.log_bucket.bucket_id
  logging_target_prefix  = "app-bucket-logs/"
  
  tags = {
    Environment = "production"
  }
  
  depends_on = [module.log_bucket]
}
```

### Cross-Region Replication

```hcl
module "source_bucket" {
  source = "./s3"

  bucket_name        = "source-bucket"
  versioning_enabled = true
  
  s3_replication_enabled    = true
  s3_replica_bucket_arn     = "arn:aws:s3:::destination-bucket"
  
  s3_replication_rules = [
    {
      id       = "replicate-all"
      priority = 1
      status   = "Enabled"
      
      filter = {
        prefix = ""
      }
      
      destination_bucket = "arn:aws:s3:::destination-bucket"
      storage_class      = "STANDARD"
    }
  ]
}
```

### Using Module Outputs

```hcl
module "app_bucket" {
  source = "./s3"

  bucket_name                      = "myapp-data"
  naming_prefix                    = "prod"
  use_naming_convention_for_bucket = true
  
  enable_bucket_logging = true
  logging_target_bucket = "my-logs-bucket"
  
  sse_algorithm      = "aws:kms"
  kms_master_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  versioning_enabled = true
}

# Use outputs in other resources
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = module.app_bucket.bucket_regional_domain_name
    origin_id   = "S3-${module.app_bucket.bucket_name}"
  }
  # ... other configuration
}

# Output important information
output "bucket_info" {
  value = {
    name                = module.app_bucket.bucket_name
    arn                 = module.app_bucket.bucket_arn
    region              = module.app_bucket.bucket_region
    encryption          = module.app_bucket.encryption_algorithm
    versioning_enabled  = module.app_bucket.versioning_enabled
    logging_enabled     = module.app_bucket.logging_enabled
  }
}

# Conditional outputs based on configuration
output "website_url" {
  value       = module.app_bucket.website_enabled ? "http://${module.app_bucket.website_endpoint}" : "Website not enabled"
  description = "The website URL if hosting is enabled"
}

output "kms_key" {
  value       = module.app_bucket.kms_key_arn != null ? module.app_bucket.kms_key_arn : "Using AES256 encryption"
  description = "KMS key information"
}
```

## Important Notes

### Security Considerations

1. **ACLs vs Bucket Policies**: AWS recommends using bucket policies instead of ACLs. The default `s3_object_ownership = "BucketOwnerEnforced"` disables ACLs. Only use ACLs if required for legacy compatibility.

2. **Public Access**: By default, public access is blocked. Only disable `restrict_public_buckets` if you need public access (e.g., static websites).

3. **Encryption**: Server-side encryption is enabled by default with AES256. Use KMS for additional key management control.

### Best Practices

- Always enable versioning for important data
- Use lifecycle rules to manage costs
- Enable SSL-only access for sensitive data
- Use KMS encryption for compliance requirements
- Tag all resources for cost tracking and organization
- Enable access logging for security audit trails
- Use lifecycle prevent_destroy for critical buckets
- Use naming conventions (prefix/suffix) for multi-environment deployments
- Apply consistent naming across dev, staging, and production

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket to be created | `string` | n/a | yes |
| bucket_prefix | Creates a unique bucket name beginning with the specified prefix (conflicts with bucket_name) | `string` | `null` | no |
| naming_prefix | Prefix to be added to all resource names (e.g., 'prod', 'dev') | `string` | `""` | no |
| naming_suffix | Suffix to be added to all resource names (e.g., 'us-east-1') | `string` | `""` | no |
| use_naming_convention_for_bucket | Apply naming_prefix and naming_suffix to bucket name | `bool` | `false` | no |
| tags | A map of tags to assign to the bucket | `map(string)` | `{}` | no |
| enable_bucket_logging | Enable S3 bucket access logging | `bool` | `false` | no |
| logging_target_bucket | The name of the bucket that will receive the log objects | `string` | `""` | no |
| logging_target_prefix | A prefix for all log object keys | `string` | `"logs/"` | no |
| enable_lifecycle_prevent_destroy | Prevent Terraform from destroying the bucket | `bool` | `false` | no |
| acl | The canned ACL to apply (conflicts with grants) | `string` | `"private"` | no |
| grants | A list of policy grants for the bucket (conflicts with acl) | `list(object)` | `[]` | no |
| force_destroy | When true, permits a non-empty bucket to be deleted | `bool` | `false` | no |
| versioning_enabled | Enable versioning for the bucket | `bool` | `true` | no |
| sse_algorithm | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| kms_master_key_arn | KMS master key ARN for SSE-KMS encryption | `string` | `""` | no |
| allow_encrypted_uploads_only | Prevent uploads of unencrypted objects | `bool` | `false` | no |
| allow_ssl_requests_only | Require HTTPS/SSL for all requests | `bool` | `false` | no |
| lifecycle_configuration_rules | List of lifecycle v2 rules | `list(object)` | `[]` | no |
| cors_configuration | CORS configuration for the bucket | `list(object)` | `null` | no |
| restrict_public_buckets | Block public bucket access | `bool` | `true` | no |
| s3_replication_enabled | Enable S3 replication (requires versioning) | `bool` | `false` | no |
| s3_replica_bucket_arn | Destination bucket ARN for replication | `string` | `""` | no |
| s3_replication_rules | Replication rules configuration | `list(any)` | `null` | no |
| s3_replication_source_roles | Cross-account IAM Role ARNs allowed to replicate to this bucket | `list(string)` | `[]` | no |
| object_lock_configuration | Object lock configuration (WORM model) | `object` | `null` | no |
| transfer_acceleration_enabled | Enable S3 transfer acceleration | `bool` | `false` | no |
| s3_object_ownership | Object ownership control (ObjectWriter, BucketOwnerPreferred, BucketOwnerEnforced) | `string` | `"BucketOwnerEnforced"` | no |
| bucket_key_enabled | Use S3 Bucket Keys for SSE-KMS | `bool` | `false` | no |
| custom_policy_enabled | Enable custom bucket policy (overrides default policy) | `bool` | `false` | no |
| custom_policy_actions | List of S3 actions for custom policy | `list(string)` | `[]` | no |
| custom_policy_account_names | List of account IDs for custom policy principals | `list(string)` | `[]` | no |
| iam_policy_statements | Map of IAM policy statements for bucket policy | `any` | `{}` | no |
| website_enabled | Enable static website hosting | `bool` | `false` | no |
| website_index_document | Index document for website | `string` | `"index.html"` | no |
| website_error_document | Error document for website | `string` | `"error.html"` | no |
| website_routing_rules | JSON array of routing rules for website | `string` | `""` | no |
| website_redirect_all_requests_to | Redirect all website requests to another host | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_name | The actual name of the bucket (important when using bucket_prefix) |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
| bucket_region | The AWS region this bucket resides in |
| website_endpoint | The website endpoint (if enabled) |
| replication_role_arn | The ARN of the replication IAM role (if enabled) |

## License

See LICENSE file in the root directory.
