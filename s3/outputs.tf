output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.default.id
}

output "bucket_name" {
  description = "The actual name of the bucket (useful when using bucket_prefix which generates random names)"
  value       = aws_s3_bucket.default.bucket
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.default.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.default.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.default.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.default.region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.default.hosted_zone_id
}

# Logging outputs
output "logging_enabled" {
  description = "Whether bucket logging is enabled"
  value       = var.enable_bucket_logging
}

output "logging_target_bucket" {
  description = "The bucket where logs are stored"
  value       = var.enable_bucket_logging ? var.logging_target_bucket : null
}

output "logging_target_prefix" {
  description = "The prefix for log objects"
  value       = var.enable_bucket_logging ? var.logging_target_prefix : null
}

# Encryption outputs
output "encryption_enabled" {
  description = "Whether server-side encryption is enabled (always true for this module)"
  value       = true
}

output "encryption_algorithm" {
  description = "The server-side encryption algorithm used"
  value       = var.sse_algorithm
}

output "kms_key_arn" {
  description = "The KMS key ARN used for encryption (if using aws:kms)"
  value       = var.sse_algorithm == "aws:kms" ? var.kms_master_key_arn : null
}

output "bucket_key_enabled" {
  description = "Whether S3 Bucket Keys are enabled for SSE-KMS"
  value       = var.bucket_key_enabled
}

# Versioning output
output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket"
  value       = var.versioning_enabled
}

# Replication outputs
output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = var.s3_replication_enabled
}

output "replication_role_arn" {
  description = "The ARN of the replication IAM Role"
  value       = var.s3_replication_enabled ? aws_iam_role.replication[0].arn : null
}

output "replication_role_name" {
  description = "The name of the replication IAM Role"
  value       = var.s3_replication_enabled ? aws_iam_role.replication[0].name : null
}

# Website outputs
output "website_enabled" {
  description = "Whether static website hosting is enabled"
  value       = var.website_enabled
}

output "website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = var.website_enabled ? aws_s3_bucket_website_configuration.default[0].website_endpoint : null
}

output "website_domain" {
  description = "The domain of the website endpoint"
  value       = var.website_enabled ? aws_s3_bucket_website_configuration.default[0].website_domain : null
}

# Security outputs
output "public_access_blocked" {
  description = "Whether public access is blocked"
  value       = var.restrict_public_buckets
}

output "ssl_requests_only" {
  description = "Whether SSL-only requests are enforced"
  value       = var.allow_ssl_requests_only
}

output "encrypted_uploads_only" {
  description = "Whether only encrypted uploads are allowed"
  value       = var.allow_encrypted_uploads_only
}

# Additional useful outputs
output "transfer_acceleration_enabled" {
  description = "Whether transfer acceleration is enabled"
  value       = var.transfer_acceleration_enabled
}

output "object_lock_enabled" {
  description = "Whether object lock is enabled"
  value       = var.object_lock_configuration != null
}

output "lifecycle_rules_count" {
  description = "Number of lifecycle rules configured"
  value       = length(var.lifecycle_configuration_rules)
}
