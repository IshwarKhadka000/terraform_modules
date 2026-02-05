variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to be created"

  validation {
    condition     = length(var.bucket_name) > 0 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a lowercase letter or number, and can only contain lowercase letters, numbers, hyphens, and periods."
  }
}

variable "bucket_prefix" {
  type        = string
  default     = null
  description = "Creates a unique bucket name beginning with the specified prefix. Conflicts with bucket_name."
}

variable "naming_prefix" {
  type        = string
  default     = ""
  description = "Prefix to be added to all resource names for naming convention (e.g., 'prod-', 'dev-')"
}

variable "naming_suffix" {
  type        = string
  default     = ""
  description = "Suffix to be added to all resource names for naming convention (e.g., '-prod', '-dev')"
}

variable "use_naming_convention_for_bucket" {
  type        = bool
  default     = false
  description = "Apply naming_prefix and naming_suffix to bucket name. Only works with bucket_name, not bucket_prefix."
}

variable "enable_bucket_logging" {
  type        = bool
  default     = false
  description = "Enable S3 bucket access logging"
}

variable "logging_target_bucket" {
  type        = string
  default     = ""
  description = "The name of the bucket that will receive the log objects"
}

variable "logging_target_prefix" {
  type        = string
  default     = "logs/"
  description = "A prefix for all log object keys"
}

variable "enable_lifecycle_prevent_destroy" {
  type        = bool
  default     = false
  description = "Prevent Terraform from destroying the bucket (requires manual removal from state)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to assign to the bucket"
}

variable "acl" {
  type = string
  default = "private"
  description = <<-EOT
  The [canned ACL](https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl) to apply.
  We recommend `private` to avoid exposing sensitive information. Conflicts with `grants`."
  EOT
}

variable "grants" {
    type = list(object({
        id = string
        type = string
        permission = list(string)
        uri = string
    }))
    default = []
    description = <<-EOT
    A list of policy grants for the bucket, taking a list of permissions.
    Conflicts with `acl`. Set `acl` to `null` to use this
    EOT
}

variable "force_destroy" {
  type = bool
  default = false
  description = <<-EOT
  When `true`, permits a non-empty s3 bucket to be deleted by first deleting all objects in the bucket.
  THESE OBJECTS ARE NOT RECOVERABLE even if they were versioned and stored in Glacier.
  EOT
}

variable "versioning_enabled" {
  type = bool
  default = true
  description = "A state of versioning. Versioning is a means of keeping multiple variants of an object in the same bucket"
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = <<-EOT
    The server-side encryption algorithm to use. 
    Valid values are `AES256` and `aws:kms`"
    EOT

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = <<-EOT
  The AWS KMS master key ARN used for the `SSE-KMS` encryption.
  This can only be used when you set the value of `sse_algorithm` as `aws:kms`. 
  The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`"
  EOT
}

variable "allow_encrypted_uploads_only" {
  type = bool
  default = false
  description = "Set to `true` to prevent uploads of unencrypted objects to S3 bucket"
}

variable "allow_ssl_requests_only" {
  type = bool
  default = false
  description = <<-EOT
  Set to `true` to require requests to use Secure Socket Layer (HTTPS/SSL). 
  This will explicitly deny access to HTTP requests
  EOT
}

variable "lifecycle_configuration_rules" {
  type = list(object({
    enabled = bool
    id = string
    abort_incomplete_multipart_upload_days = number
    
    # `filter_and` is the `and` configuration block inside the `filter` configuration.
    # This is the only place you should specify a prefix.
    filter_and = any
    expiration = any
    transition = list(any)

    noncurrent_version_expiration = any
    noncurrent_version_transition = list(any)
  }))
  default = []
  description = "A list of lifecycle v2 rules"
}

variable "cors_configuration" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers = list(string)
    max_age_seconds = number 
  }))
  default = null
  description = <<-EOT
  Specifies the allowed headers, methods, origins and exposed headers when using CORS on this bucket
  EOT
}

variable "restrict_public_buckets" {
  type = bool
  default = true
  description = "Set to `false` to disable the restricting of making the bucket public"
}

variable "s3_replication_enabled" {
  type = bool
  default = false
  description = <<-EOT
  Set this to true and specify `s3_replication_rules` to enable replication.
  `versioning_enabled` must also be `true`."
  EOT
}

variable "s3_replica_bucket_arn" {
  type = string
  default = ""
  description = <<-EOT
  A single S3 bucket ARN to use for all replication rules.
  Note: The destination bucket can be specified in the replication rule itself
  (which allows for multiple destinations), in which case it will take precedence over this variable.
  EOT
}

variable "s3_replication_rules" {
  type = list(any)
  default = null
  description = <<-EOT
  Specifies the replication rules for S3 bucket replication if enabled.
  You must also set s3_replication_enabled to true.
  EOT
}

variable "s3_replication_source_roles" {
  type = list(string)
  default = []
  description = "Cross-account IAM Role ARNs that will be allowed to perform S3 replication to this bucket (for replication within the same AWS account, it's not necessary to adjust the bucket policy)."
}

variable "object_lock_configuration" {
  type = object({
    mode = string # Valid values are GOVERNANCE and COMPLIANCE.
    days = number
    years = number 
  })
  default = null
  description = <<-EOT
  A configuration for S3 object locking.
  With S3 Object Lock, you can store objects using a `write once, read many` (WORM) model.
  Object Lock can help prevent objects from being deleted or overwritten for a fixed amount of time or indefinitely.
  EOT
}

variable "transfer_acceleration_enabled" {
  type = bool
  default = false
  description = "Set this to `true` to enable s3 transfer acceleration for the bucket"
}

variable "s3_object_ownership" {
  type        = string
  default     = "BucketOwnerEnforced"
  description = "Specifies the S3 object ownership control. Valid values are `ObjectWriter`, `BucketOwnerPreferred`, and 'BucketOwnerEnforced'."

  validation {
    condition     = contains(["ObjectWriter", "BucketOwnerPreferred", "BucketOwnerEnforced"], var.s3_object_ownership)
    error_message = "s3_object_ownership must be one of: ObjectWriter, BucketOwnerPreferred, BucketOwnerEnforced."
  }
}

variable "bucket_key_enabled" {
  type = bool
  default = false
  description = <<-EOT
  Set this to `true` to use Amazon S3 Bucket Keys for SSE-KMS, which reduce the cost of AWS KMS requests.
  EOT
}

variable "custom_policy_actions" {  
  description = "List of S3 Actions for the custom policy"
  type        = list(string)
  default     = []
}

variable "custom_policy_account_names" {
  description = "List of accounts names to assign as principals for the s3 bucket custom policy"
  type = list(string)
  default = []
}

variable "custom_policy_enabled" {
  description = "Whether to enable or disable the custom policy. If enabled, the default policy will be ignored."
  type = bool

  default = false
}

variable "iam_policy_statements" {
  type = any
  description = "Map of IAM policy statements to use in the bucket policy"
  default = {}
}

variable "website_enabled" {
  type = bool
  default = false
  description = "Set to `true` to enable static website hosting for this bucket"
}

variable "website_index_document" {
  type = string
  default = "index.html"
  description = "The name of the index document for the website"
}

variable "website_error_document" {
  type = string
  default = "error.html"
  description = "The name of the error document for the website"
}

variable "website_routing_rules" {
  type = string
  default = ""
  description = "A json array containing routing rules describing redirect behavior and when redirects are applied"
}

variable "website_redirect_all_requests_to" {
  type = object({
    host_name = string
    protocol  = string
  })
  default = null
  description = "A hostname to redirect all website requests for this bucket to. If this is set, it will override other website settings."
}
