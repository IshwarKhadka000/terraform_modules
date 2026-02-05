resource "aws_s3_bucket" "default" {
  bucket        = local.bucket_name_final
  bucket_prefix = local.bucket_prefix_final
  force_destroy = var.force_destroy

  tags = local.tags

  lifecycle {
    prevent_destroy = var.enable_lifecycle_prevent_destroy
  }
}

# S3 bucket logging
resource "aws_s3_bucket_logging" "default" {
  count  = var.enable_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.default.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.default.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_master_key_arn != "" ? var.kms_master_key_arn : null
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

# S3 bucket ACL
# Note: AWS recommends using bucket policies instead of ACLs for access control
# ACLs are considered legacy. Use only if required for specific use cases.
resource "aws_s3_bucket_acl" "default" {
  count  = var.s3_object_ownership != "BucketOwnerEnforced" && length(var.grants) == 0 ? 1 : 0
  bucket = aws_s3_bucket.default.id
  acl    = var.acl

  depends_on = [aws_s3_bucket_ownership_controls.default]
}

# S3 bucket grants
resource "aws_s3_bucket_acl" "default_with_grants" {
  count  = var.s3_object_ownership != "BucketOwnerEnforced" && length(var.grants) > 0 ? 1 : 0
  bucket = aws_s3_bucket.default.id

  dynamic "access_control_policy" {
    for_each = length(var.grants) > 0 ? [1] : []

    content {
      dynamic "grant" {
        for_each = var.grants

        content {
          grantee {
            id   = grant.value.id
            type = grant.value.type
            uri  = grant.value.uri
          }
          permission = grant.value.permission
        }
      }

      owner {
        id = data.aws_canonical_user_id.current.id
      }
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.default]
}

data "aws_canonical_user_id" "current" {
  count = var.s3_object_ownership != "BucketOwnerEnforced" && length(var.grants) > 0 ? 1 : 0
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id

  rule {
    object_ownership = var.s3_object_ownership
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = var.restrict_public_buckets
  block_public_policy     = var.restrict_public_buckets
  ignore_public_acls      = var.restrict_public_buckets
  restrict_public_buckets = var.restrict_public_buckets
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "default" {
  count  = length(var.lifecycle_configuration_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.default.id

  dynamic "rule" {
    for_each = var.lifecycle_configuration_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }

      dynamic "filter" {
        for_each = rule.value.filter_and != null ? [rule.value.filter_and] : []

        content {
          and {
            prefix = lookup(filter.value, "prefix", null)
            tags   = lookup(filter.value, "tags", null)
          }
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []

        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days = lookup(noncurrent_version_expiration.value, "noncurrent_days", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []

        content {
          noncurrent_days = lookup(noncurrent_version_transition.value, "noncurrent_days", null)
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "default" {
  count  = var.cors_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.default.id

  dynamic "cors_rule" {
    for_each = var.cors_configuration

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# S3 bucket transfer acceleration
resource "aws_s3_bucket_accelerate_configuration" "default" {
  count  = var.transfer_acceleration_enabled ? 1 : 0
  bucket = aws_s3_bucket.default.id
  status = "Enabled"
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "default" {
  count  = var.website_enabled ? 1 : 0
  bucket = aws_s3_bucket.default.id

  dynamic "index_document" {
    for_each = var.website_redirect_all_requests_to == null ? [1] : []

    content {
      suffix = var.website_index_document
    }
  }

  dynamic "error_document" {
    for_each = var.website_redirect_all_requests_to == null && var.website_error_document != "" ? [1] : []

    content {
      key = var.website_error_document
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website_redirect_all_requests_to != null ? [var.website_redirect_all_requests_to] : []

    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }

  routing_rules = var.website_routing_rules != "" ? var.website_routing_rules : null
}

# S3 bucket object lock configuration
resource "aws_s3_bucket_object_lock_configuration" "default" {
  count  = var.object_lock_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.default.id

  rule {
    default_retention {
      mode  = var.object_lock_configuration.mode
      days  = var.object_lock_configuration.days
      years = var.object_lock_configuration.years
    }
  }
}

# S3 bucket policy
data "aws_iam_policy_document" "bucket_policy" {
  count = var.custom_policy_enabled ? 0 : 1

  source_policy_documents = local.policy_documents

  dynamic "statement" {
    for_each = var.iam_policy_statements

    content {
      sid       = lookup(statement.value, "sid", statement.key)
      effect    = lookup(statement.value, "effect", null)
      actions   = lookup(statement.value, "actions", null)
      resources = lookup(statement.value, "resources", null)

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

data "aws_iam_policy_document" "require_encrypted_uploads" {
  count = var.allow_encrypted_uploads_only ? 1 : 0

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.default.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [var.sse_algorithm]
    }
  }
}

data "aws_iam_policy_document" "require_ssl_requests" {
  count = var.allow_ssl_requests_only ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.default.arn,
      "${aws_s3_bucket.default.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "replication_source" {
  count = length(var.s3_replication_source_roles) > 0 ? 1 : 0

  statement {
    sid    = "AllowReplicationSource"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.s3_replication_source_roles
    }

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging"
    ]

    resources = ["${aws_s3_bucket.default.arn}/*"]
  }
}

data "aws_iam_policy_document" "custom_policy" {
  count = var.custom_policy_enabled ? 1 : 0

  statement {
    sid    = "CustomPolicy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [for account in var.custom_policy_account_names : "arn:aws:iam::${account}:root"]
    }

    actions   = var.custom_policy_actions
    resources = ["${aws_s3_bucket.default.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "default" {
  count  = local.bucket_policy_enabled ? 1 : 0
  bucket = aws_s3_bucket.default.id
  policy = var.custom_policy_enabled ? data.aws_iam_policy_document.custom_policy[0].json : data.aws_iam_policy_document.bucket_policy[0].json

  depends_on = [aws_s3_bucket_public_access_block.default]
}

# S3 bucket replication configuration
resource "aws_iam_role" "replication" {
  count       = var.s3_replication_enabled ? 1 : 0
  name_prefix = "${local.iam_name_prefix}-replication-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "replication" {
  count       = var.s3_replication_enabled ? 1 : 0
  name_prefix = "${local.iam_name_prefix}-replication-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.default.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.default.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${var.s3_replica_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.s3_replication_enabled ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "default" {
  count  = var.s3_replication_enabled && var.s3_replication_rules != null ? 1 : 0
  bucket = aws_s3_bucket.default.id
  role   = aws_iam_role.replication[0].arn

  dynamic "rule" {
    for_each = var.s3_replication_rules

    content {
      id       = lookup(rule.value, "id", null)
      priority = lookup(rule.value, "priority", 0)
      status   = lookup(rule.value, "status", "Enabled")

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []

        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      destination {
        bucket        = lookup(rule.value, "destination_bucket", var.s3_replica_bucket_arn)
        storage_class = lookup(rule.value, "storage_class", "STANDARD")

        dynamic "replication_time" {
          for_each = lookup(rule.value, "replication_time", null) != null ? [rule.value.replication_time] : []

          content {
            status = replication_time.value.status
            time {
              minutes = replication_time.value.minutes
            }
          }
        }

        dynamic "metrics" {
          for_each = lookup(rule.value, "metrics", null) != null ? [rule.value.metrics] : []

          content {
            status = metrics.value.status
            event_threshold {
              minutes = metrics.value.minutes
            }
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = lookup(rule.value, "source_selection_criteria", null) != null ? [rule.value.source_selection_criteria] : []

        content {
          dynamic "sse_kms_encrypted_objects" {
            for_each = lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", null) != null ? [source_selection_criteria.value.sse_kms_encrypted_objects] : []

            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = lookup(rule.value, "delete_marker_replication_status", null) != null ? [1] : []

        content {
          status = rule.value.delete_marker_replication_status
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.default]
}
