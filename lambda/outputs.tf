output "lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = try(aws_lambda_function.this[0].arn, null)
}

output "lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = try(aws_lambda_function.this[0].function_name, null)
}

output "lambda_function_invoke_arn" {
  description = "The Invoke ARN of the Lambda Function"
  value       = try(aws_lambda_function.this[0].invoke_arn, null)
}

output "lambda_function_qualified_arn" {
  description = "The ARN identifying your Lambda Function Version"
  value       = try(aws_lambda_function.this[0].qualified_arn, null)
}

output "lambda_function_version" {
  description = "Latest published version of Lambda Function"
  value       = try(aws_lambda_function.this[0].version, null)
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role created for the Lambda Function"
  value       = try(aws_iam_role.lambda[0].arn, null)
}

output "lambda_role_name" {
  description = "The name of the IAM role created for the Lambda Function"
  value       = try(aws_iam_role.lambda[0].name, null)
}

output "lambda_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.lambda[0].arn, null)
}

output "lambda_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.lambda[0].name, null)
}

output "lambda_layer_arn" {
  description = "The ARN of the Lambda Layer"
  value       = try(aws_lambda_layer_version.this[0].arn, null)
}

output "lambda_layer_version" {
  description = "The version of the Lambda Layer"
  value       = try(aws_lambda_layer_version.this[0].version, null)
}

output "lambda_layer_created_date" {
  description = "The date the Lambda Layer was created"
  value       = try(aws_lambda_layer_version.this[0].created_date, null)
}
