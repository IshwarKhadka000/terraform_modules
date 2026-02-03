# AWS Lambda Terraform Module

A comprehensive Terraform module for deploying AWS Lambda functions and layers with automatic redeployment on code changes.

## Features

- **Automatic Redeployment**: Detects changes in local source code, local zip files, and S3-hosted packages using ETag-based change detection
- **Multiple Deployment Methods**: Support for local source directories, pre-built zip files, S3 packages, and container images
- **IAM Role Management**: Automatic IAM role creation with customizable policies
- **VPC Support**: Deploy Lambda functions within VPC with subnet and security group configuration
- **CloudWatch Logs**: Automatic log group creation with configurable retention
- **Lambda Layers**: Create and attach Lambda layers from local or S3 sources
- **Trigger Permissions**: Configure Lambda permissions for various AWS service triggers
- **Environment Variables**: Easy configuration of runtime environment variables

## Usage Examples

### Example 1: Lambda from Local Source Directory

```hcl
module "lambda_from_source" {
  source = "./lambda"

  function_name = "my-lambda-function"
  description   = "Lambda function built from local source"
  runtime       = "python3.11"
  handler       = "index.handler"
  
  source_path = "${path.module}/src/lambda"
  
  memory_size = 256
  timeout     = 30
  
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Example 2: Lambda from Pre-built Local Zip File

```hcl
module "lambda_from_zip" {
  source = "./lambda"

  function_name = "my-lambda-function"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  
  local_existing_package = "${path.module}/builds/lambda.zip"
  
  memory_size = 512
  timeout     = 60
}
```

### Example 3: Lambda from S3 Package (with Auto-Redeployment)

```hcl
module "lambda_from_s3" {
  source = "./lambda"

  function_name = "my-lambda-function"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  
  s3_existing_package = {
    bucket  = "my-lambda-artifacts"
    key     = "functions/my-function.zip"
    version = "v1.2.3"  # Optional: for versioned buckets
  }
  
  memory_size = 1024
  timeout     = 300
}
```

### Example 4: Lambda with VPC Configuration

```hcl
module "lambda_in_vpc" {
  source = "./lambda"

  function_name = "vpc-lambda-function"
  runtime       = "python3.11"
  handler       = "app.handler"
  
  source_path = "${path.module}/src/vpc-lambda"
  
  vpc_subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  vpc_security_group_ids = ["sg-12345678"]
  
  attach_network_policy = true
  
  memory_size = 512
  timeout     = 120
}
```

### Example 5: Lambda with Custom IAM Role

```hcl
module "lambda_custom_role" {
  source = "./lambda"

  function_name = "custom-role-lambda"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  
  source_path = "${path.module}/src/lambda"
  
  create_role       = false
  lambda_role       = aws_iam_role.custom_lambda_role.arn
}

resource "aws_iam_role" "custom_lambda_role" {
  name = "custom-lambda-role"
  
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
}
```

### Example 6: Lambda with API Gateway Trigger

```hcl
module "lambda_with_api_gateway" {
  source = "./lambda"

  function_name = "api-lambda"
  runtime       = "python3.11"
  handler       = "api.handler"
  
  source_path = "${path.module}/src/api"
  
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }
}
```

### Example 7: Lambda with S3 Event Trigger

```hcl
module "lambda_s3_trigger" {
  source = "./lambda"

  function_name = "s3-event-processor"
  runtime       = "python3.11"
  handler       = "processor.handler"
  
  source_path = "${path.module}/src/processor"
  
  allowed_triggers = {
    S3Bucket = {
      service    = "s3"
      source_arn = aws_s3_bucket.uploads.arn
    }
  }
  
  memory_size = 1024
  timeout     = 300
}
```

### Example 8: Lambda with Environment Variables and Dead Letter Queue

```hcl
module "lambda_with_dlq" {
  source = "./lambda"

  function_name = "reliable-lambda"
  runtime       = "python3.11"
  handler       = "main.handler"
  
  source_path = "${path.module}/src/main"
  
  environment_variables = {
    DATABASE_URL = "postgresql://..."
    API_KEY      = var.api_key
    REGION       = var.aws_region
  }
  
  dead_letter_target_arn = aws_sqs_queue.dlq.arn
  
  timeout = 60
}

resource "aws_sqs_queue" "dlq" {
  name = "lambda-dlq"
}
```

### Example 9: Lambda Layer Creation

```hcl
module "lambda_layer" {
  source = "./lambda"

  create_function = false
  create_layer    = true
  
  layer_name          = "my-dependencies-layer"
  description         = "Python dependencies layer"
  layer_source_path   = "${path.module}/layers/python"
  
  compatible_runtimes      = ["python3.9", "python3.10", "python3.11"]
  compatible_architectures = ["x86_64", "arm64"]
}
```

### Example 10: Lambda with Layer Attached

```hcl
module "dependencies_layer" {
  source = "./lambda"

  create_function = false
  create_layer    = true
  
  layer_name        = "dependencies"
  layer_source_path = "${path.module}/layers/dependencies"
  
  compatible_runtimes = ["python3.11"]
}

module "lambda_with_layer" {
  source = "./lambda"

  function_name = "lambda-with-dependencies"
  runtime       = "python3.11"
  handler       = "app.handler"
  
  source_path = "${path.module}/src/app"
  
  layers = [module.dependencies_layer.lambda_layer_arn]
}
```

### Example 11: Lambda with Container Image

```hcl
module "lambda_container" {
  source = "./lambda"

  function_name = "container-lambda"
  
  image_uri = "${aws_ecr_repository.lambda.repository_url}:latest"
  
  image_config_entry_point = ["/lambda-entrypoint.sh"]
  image_config_command     = ["app.handler"]
  
  memory_size = 2048
  timeout     = 900
}
```

### Example 12: Lambda with CloudWatch Logs Configuration

```hcl
module "lambda_with_logs" {
  source = "./lambda"

  function_name = "logged-lambda"
  runtime       = "python3.11"
  handler       = "main.handler"
  
  source_path = "${path.module}/src/main"
  
  cloudwatch_logs_retention_in_days = 7
  cloudwatch_logs_kms_key_id        = aws_kms_key.logs.arn
  
  attach_cloudwatch_logs_policy = true
}
```

### Example 13: Lambda with ARM64 Architecture

```hcl
module "lambda_arm64" {
  source = "./lambda"

  function_name = "arm-lambda"
  runtime       = "python3.11"
  handler       = "index.handler"
  
  source_path = "${path.module}/src/lambda"
  
  architectures = ["arm64"]
  memory_size   = 512
}
```

### Example 14: Complete Production Lambda Setup

```hcl
module "production_lambda" {
  source = "./lambda"

  function_name = "production-api"
  description   = "Production API Lambda function"
  runtime       = "python3.11"
  handler       = "api.handler"
  
  source_path = "${path.module}/src/api"
  
  # Performance
  memory_size            = 1024
  timeout                = 30
  ephemeral_storage_size = 1024
  architectures          = ["arm64"]
  
  # Networking
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.lambda.id]
  attach_network_policy  = true
  
  # Environment
  environment_variables = {
    ENVIRONMENT  = "production"
    DATABASE_URL = var.database_url
    CACHE_URL    = var.redis_url
    LOG_LEVEL    = "INFO"
  }
  
  # Reliability
  dead_letter_target_arn = aws_sqs_queue.dlq.arn
  
  # Logging
  cloudwatch_logs_retention_in_days = 30
  cloudwatch_logs_kms_key_id        = aws_kms_key.logs.arn
  
  # Triggers
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }
  
  # Versioning
  publish = true
  
  # Tags
  tags = {
    Environment = "production"
    Application = "api"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

## Automatic Redeployment

This module automatically detects code changes and triggers Lambda redeployment:

- **Local Source Code**: Changes detected via archive file hash
- **Local Zip Files**: Changes detected via file hash
- **S3 Packages**: Changes detected via S3 object ETag (no versioning required!)

When you update your Lambda code in S3, simply run `terraform apply` and the module will detect the change and redeploy automatically.

## Inputs

### Core Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create | Controls whether resources should be created | `bool` | `true` | no |
| create_function | Controls whether Lambda function should be created | `bool` | `true` | no |
| function_name | Name of the Lambda function | `string` | `""` | yes |
| description | Description of the Lambda function | `string` | `""` | no |
| runtime | Runtime of the Lambda function | `string` | `""` | yes* |
| handler | Entrypoint in the code for the Lambda function | `string` | `""` | yes* |

*Required unless using container image

### Package Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| source_path | Path to local directory containing Lambda source code | `any` | `null` | no |
| local_existing_package | Path to existing zip file | `string` | `null` | no |
| s3_existing_package | S3 bucket object with keys: bucket, key, version | `map(string)` | `null` | no |
| image_uri | ECR image URI for container-based Lambda | `string` | `""` | no |

### Performance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| memory_size | Memory in MB (128-10240) | `number` | `128` | no |
| timeout | Timeout in seconds | `number` | `3` | no |
| ephemeral_storage_size | Ephemeral storage in MB (512-10240) | `number` | `512` | no |
| architectures | Instruction set architecture | `list(string)` | `null` | no |

### Networking Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_subnet_ids | List of subnet IDs | `list(string)` | `null` | no |
| vpc_security_group_ids | List of security group IDs | `list(string)` | `null` | no |
| attach_network_policy | Attach VPC execution role policy | `bool` | `false` | no |

### IAM Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_role | Create IAM role for Lambda | `bool` | `true` | no |
| lambda_role | Existing IAM role ARN to use | `string` | `""` | no |
| role_name | Name of IAM role | `string` | `null` | no |
| role_description | Description of IAM role | `string` | `""` | no |

### CloudWatch Logs Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| attach_cloudwatch_logs_policy | Attach CloudWatch logs policy | `bool` | `true` | no |
| cloudwatch_logs_retention_in_days | Log retention in days | `number` | `null` | no |
| cloudwatch_logs_kms_key_id | KMS key ARN for log encryption | `string` | `null` | no |
| use_existing_cloudwatch_log_group | Use existing log group | `bool` | `false` | no |

### Environment Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment_variables | Map of environment variables | `map(string)` | `{}` | no |

### Layer Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create_layer | Create Lambda layer | `bool` | `false` | no |
| layer_name | Name of Lambda layer | `string` | `""` | no |
| layer_source_path | Path to layer source code | `any` | `null` | no |
| layer_local_existing_package | Path to existing layer zip | `string` | `null` | no |
| layer_s3_existing_package | S3 object for layer package | `map(string)` | `null` | no |
| compatible_runtimes | Compatible runtimes for layer | `list(string)` | `[]` | no |
| compatible_architectures | Compatible architectures for layer | `list(string)` | `null` | no |
| layers | List of layer ARNs to attach | `list(string)` | `null` | no |

### Trigger Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| allowed_triggers | Map of allowed triggers | `map(any)` | `{}` | no |

### Other Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| publish | Publish Lambda version | `bool` | `false` | no |
| dead_letter_target_arn | ARN of SNS/SQS for failed invocations | `string` | `null` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |
| function_tags | Tags only for Lambda function | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | The ARN of the Lambda Function |
| lambda_function_name | The name of the Lambda Function |
| lambda_function_invoke_arn | The Invoke ARN of the Lambda Function |
| lambda_function_qualified_arn | The ARN identifying your Lambda Function Version |
| lambda_function_version | Latest published version of Lambda Function |
| lambda_role_arn | The ARN of the IAM role created for the Lambda Function |
| lambda_role_name | The name of the IAM role created for the Lambda Function |
| lambda_cloudwatch_log_group_arn | The ARN of the CloudWatch Log Group |
| lambda_cloudwatch_log_group_name | The name of the CloudWatch Log Group |
| lambda_layer_arn | The ARN of the Lambda Layer |
| lambda_layer_version | The version of the Lambda Layer |
| lambda_layer_created_date | The date the Lambda Layer was created |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## License

See LICENSE file in the repository root.
