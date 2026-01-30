locals {
  create = var.create
  
  # Determine if we're building from source
  build_from_source = var.source_path != null
  
  # Package file path
  filename = var.local_existing_package != null ? var.local_existing_package : (
    local.build_from_source ? "${path.module}/.terraform/tmp/${var.function_name}.zip" : ""
  )

  # S3 configuration for Lambda function
  s3_bucket = var.s3_existing_package != null ? try(var.s3_existing_package.bucket, null) : ""
  s3_key    = var.s3_existing_package != null ? try(var.s3_existing_package.key, null) : ""
  
  # Layer configuration
  build_layer_from_source = var.create_layer && var.layer_source_path != null
  layer_filename = var.layer_local_existing_package != null ? var.layer_local_existing_package : (
    local.build_layer_from_source ? "${path.module}/.terraform/tmp/${var.layer_name}.zip" : ""
  )
  
  # S3 configuration for Lambda layer
  layer_s3_bucket = var.layer_s3_existing_package != null ? try(var.layer_s3_existing_package.bucket, null) : ""
  layer_s3_key    = var.layer_s3_existing_package != null ? try(var.layer_s3_existing_package.key, null) : ""
}


# Build package from source
data "archive_file" "lambda_package" {
  count = local.create && var.create_function && local.build_from_source ? 1 : 0

  type        = "zip"
  source_dir  = var.source_path
  output_path = local.filename
}

# Build layer package from source
data "archive_file" "layer_package" {
  count = local.create && var.create_layer && local.build_layer_from_source ? 1 : 0

  type        = "zip"
  source_dir  = var.layer_source_path
  output_path = local.layer_filename
}

resource "aws_iam_role" "lambda" {
  count = local.create && var.create_function && var.create_role ? 1 : 0

  name        = var.role_name != null ? var.role_name : var.function_name
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, var.function_tags)
}

resource "aws_lambda_function" "this" {
  count = var.create && var.create_function ? 1 : 0

  function_name = var.function_name
  description   = var.description
  role          = var.create_role ? aws_iam_role.lambda[0].arn : var.lambda_role

  # Package configuration
  filename         = var.local_existing_package != null || local.build_from_source ? local.filename : null
  source_code_hash = var.local_existing_package != null || local.build_from_source ? filebase64sha256(local.filename) : null

  s3_bucket         = var.s3_existing_package != null ? try(var.s3_existing_package.bucket, null) : null
  s3_key            = var.s3_existing_package != null ? try(var.s3_existing_package.key, null) : null
  s3_object_version = var.s3_existing_package != null ? try(var.s3_existing_package.version, null) : null

  image_uri = var.image_uri != "" ? var.image_uri : null

  runtime = var.runtime != "" ? var.runtime : null
  handler = var.handler != "" ? var.handler : null

  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = var.publish
  layers        = var.layers

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size == null ? [] : [true]

    content {
      size = var.ephemeral_storage_size
    }
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null && var.vpc_security_group_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "image_config" {
    for_each = length(var.image_config_entry_point) > 0 || length(var.image_config_command) > 0 || var.image_config_working_directory != null ? [1] : []
    content {
      entry_point       = var.image_config_entry_point
      command           = var.image_config_command
      working_directory = var.image_config_working_directory
    }
  }

  tags = merge(var.tags, var.function_tags)

  depends_on = [aws_cloudwatch_log_group.lambda]
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  count = local.create && var.create_function && !var.use_existing_cloudwatch_log_group ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.cloudwatch_logs_kms_key_id

  tags = merge(var.tags, var.function_tags)
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "logs" {
  count = local.create && var.create_function && var.create_role && var.attach_cloudwatch_logs_policy ? 1 : 0

  name = "${var.policy_name != null ? var.policy_name : var.function_name}-logs"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda[0].arn}:*"
      }],
      var.attach_create_log_group_permission ? [{
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }] : []
    )
  })
}

# IAM Policy for VPC
resource "aws_iam_role_policy_attachment" "vpc" {
  count = local.create && var.create_function && var.create_role && var.attach_network_policy ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Permission for triggers
resource "aws_lambda_permission" "allowed_triggers" {
  for_each = local.create && var.create_function ? var.allowed_triggers : {}

  function_name = aws_lambda_function.this[0].function_name

  statement_id       = try(each.value.statement_id, each.key)
  action             = try(each.value.action, "lambda:InvokeFunction")
  principal          = try(each.value.principal, format("%s.amazonaws.com", try(each.value.service, "")))
  source_arn         = try(each.value.source_arn, null)
  source_account     = try(each.value.source_account, null)
  principal_org_id   = try(each.value.principal_org_id, null)
  function_url_auth_type = try(each.value.function_url_auth_type, null)
}

# Lambda Layer
resource "aws_lambda_layer_version" "this" {
  count = local.create && var.create_layer ? 1 : 0

  layer_name          = var.layer_name
  description         = var.description
  compatible_runtimes = var.compatible_runtimes

  filename         = var.layer_local_existing_package != null || local.build_layer_from_source ? local.layer_filename : null
  source_code_hash = var.layer_local_existing_package != null || local.build_layer_from_source ? filebase64sha256(local.layer_filename) : null

  s3_bucket         = var.layer_s3_existing_package != null ? local.layer_s3_bucket : null
  s3_key            = var.layer_s3_existing_package != null ? local.layer_s3_key : null
  s3_object_version = var.layer_s3_existing_package != null ? try(var.layer_s3_existing_package.version, null) : null

  compatible_architectures = var.compatible_architectures

  skip_destroy = false
}
