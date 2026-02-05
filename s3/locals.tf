locals {
  # Determine if bucket policy is needed
  bucket_policy_enabled = (
    var.custom_policy_enabled ||
    var.allow_encrypted_uploads_only ||
    var.allow_ssl_requests_only ||
    length(var.s3_replication_source_roles) > 0 ||
    length(var.iam_policy_statements) > 0
  )

  # Collect policy documents that are actually enabled
  policy_documents = compact([
    var.allow_encrypted_uploads_only ? data.aws_iam_policy_document.require_encrypted_uploads[0].json : "",
    var.allow_ssl_requests_only ? data.aws_iam_policy_document.require_ssl_requests[0].json : "",
    length(var.s3_replication_source_roles) > 0 ? data.aws_iam_policy_document.replication_source[0].json : ""
  ])

  # Naming convention helpers
  naming_prefix = var.naming_prefix != "" ? "${var.naming_prefix}-" : ""
  naming_suffix = var.naming_suffix != "" ? "-${var.naming_suffix}" : ""
  
  # Bucket name with optional naming convention
  bucket_name_final = var.bucket_prefix != null ? null : (
    var.use_naming_convention_for_bucket ? 
    "${local.naming_prefix}${var.bucket_name}${local.naming_suffix}" : 
    var.bucket_name
  )
  
  # Bucket prefix with naming convention
  bucket_prefix_final = var.bucket_prefix != null ? "${local.naming_prefix}${var.bucket_prefix}" : null
  
  # IAM resource name prefix
  iam_name_prefix = "${local.naming_prefix}${var.bucket_name}${local.naming_suffix}"

  # Merge default tags with user-provided tags
  tags = merge(
    {
      Name      = var.bucket_name
      ManagedBy = "Terraform"
    },
    var.tags
  )
}
