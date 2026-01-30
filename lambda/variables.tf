variable "create" {
  type = bool
  default = true
  description = "Controls whether resources should be created or not"
}

variable "create_function" {
  type = bool
  default = true
  description = "Controls whether lambda function should be created or not"
}

variable "create_role" {
  type = bool
  default = true
  description = "Controls whether IAM role for lambda function should be created or not"
}

variable "create_layer" {
  type = bool
  default = false
  description = "Controls whether lambda layer should be created or not"
}

variable "create_function_url" {
  type = bool
  default = false
  description = "Controls whether lambda function url should be created"
}


############ function variables ###########
variable "function_name" {
  type = string
  default = ""
  description = "Name of the lambda function"
}

variable "description" {
  type = string
  default = ""
  description = "Description of the lambda function(or layer)"
}

variable "runtime" {
  type = string
  default = ""
  description = "Runtime of the lambda function"
}

variable "handler" {
    type = string
  default = ""
  description = "Entrypoint in the code for the lambda function"
}

variable "lambda_role" {
  type = string
  default = ""
  description = "IAM role ARN attached to the Lambda Function. This governs both who / what can invoke the Lambda Function, as well as what resources our Lambda Function has access to."
}

variable "layers" {
  type = list(string)
  default = null
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
}

variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function. Valid values are [\"x86_64\"] and [\"arm64\"]."
  type        = list(string)
  default     = null
}

variable "memory_size" {
  type = number
  default = 128
  description = "Amount of memory in MB Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments."
}

variable "ephemeral_storage_size" {
  type = number
  default = 512
  description = "Amount of ephemeral storage (/tmp) in MB Lambda Function can use at runtime. Valid value between 512 MB to 10,240 MB (10 GB)."
}

variable "publish" {
  type = bool
  default = false
  description = "Whether to publish creation/change as new Lambda Function Version."
}

variable "timeout" {
  type = number
  default = 3
  description = "The amount of time Lambda Function has to run in seconds."
}

variable "dead_letter_target_arn" {
  type = string
  default = null
  description = "The ARN of an SNS topic or SQS queue to notify when an invocation fails."
}

variable "environment_variables" {
  type = map(string)
  default = {}
}

variable "vpc_subnet_ids" {
  type = list(string)
  default = null
  description = "List of subnet ids when Lambda function should run in the VPC. Usually private subnets"
}

variable "vpc_security_group_ids" {
  type = list(string)
  default = null
  description = "List of security group ids when Lambda function should run in the VPC"
}

variable "function_tags" {
  type = map(string)
  default = {}
  description = "A map of tags to assign only to the Lambda function"
}

variable "image_uri" {
  type = string
  default = ""
  description = "The ECR image URI containing the function's deployment package."
}

variable "image_config_entry_point" {
  type        = list(string)
  default     = []
  description = "The ENTRYPOINT for the docker image"
}

variable "image_config_command" {
  type        = list(string)
  default     = []
  description = "The CMD for the docker image"
}

variable "image_config_working_directory" {
  type        = string
  default     = null
  description = "The working directory for the docker image"
}

variable "tags" {
  type = map(string)
  default = {}
  description = "Tags for the lambda function being created"
}

#### Function URL ####
variable "create_unqualified_alias_lambda_function_url" {
  type        = bool
  default     = true
  description = "Whether to use unqualified alias pointing to $LATEST version in Lambda Function URL"
}

variable "authorization_type" {
  type        = string
  default     = "NONE"
  description = "The type of authentication that the Lambda Function URL uses. Set to 'AWS_IAM' to restrict access to authenticated IAM users only. Set to 'NONE' to bypass IAM authentication and create a public endpoint."
}

variable "cors" {
  type        = any
  default     = {}
  description = "CORS settings to be used by the Lambda Function URL"
}


### Layer ####
variable "layer_name" {
  type = string
  default = ""
  description = "Name of Lambda layer to create"
}

variable "compatible_runtimes" {
  type = list(string)
  default = []
  description = "A list of Runtimes this layer is compatible with. Up to 5 runtimes can be specified."
}

variable "compatible_architectures" {
  type = list(string)
  default = null
  description = "A list of Architectures Lambda layer is compatible with. Currently x86_64 and arm64 can be specified."
}


##### Lambda permissions
variable "allowed_triggers" {
  type = map(any)
  default = {}
  description = "Map of allowed triggers to create lambda permissions"
}

#### Lambda Event Source Mapping
variable "event_source_mapping" {
  type = any
  default = {}
  description = "Map of event source mapping"
}

#### Cloudwatch logs
variable "use_existing_cloudwatch_log_group" {
  type = bool
  default = false
  description = "value"
}

variable "cloudwatch_logs_retention_in_days" {
  type = number
  default = null
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
}

variable "cloudwatch_logs_kms_key_id" {
  type = string
  default = null
  description = "The ARN of the KMS Key to use when encrypting log data"
}

#### IAM
variable "role_name" {
  type = string
  default = null
  description = "Name of the IAM role to use for lambda function"
}

variable "role_description" {
  type = string
  default = ""
  description = "Description of the IAM role to use for lambda function"
}

#### Policies
variable "policy_name" {
    type = string
    default = null
  description = "IAM Policy Name. It overrides the default name, which is the same as role_name"
}

variable "attach_cloudwatch_logs_policy" {
  type = bool
  default = true
  description = "Controls whether cloudwatch logs policy should be added to IAM role for Lambda Function"
}

variable "attach_create_log_group_permission" {
  type = bool
  default = true
  description = "Controls whether to add the create log group permission to the CloudWatch logs policy"
}

variable "attach_dead_letter_policy" {
  type = bool
  default = false
  description = "Controls whether SNS/SQS dead letter notification policy should be added to IAM role for Lambda Function"
}

variable "attach_network_policy" {
  type        = bool
  default     = false
  description = "Controls whether VPC/network policy should be added to IAM role for Lambda Function"
}

variable "attach_policy_json" {
  type = bool
  default = false
  description = "Controls whether policy_json should be added to IAM role for Lambda Function"
}

variable "attach_policy_jsons" {
  type = bool
  default = false
  description = "Controls whether policy_jsons should be added to IAM role for Lambda Function"
}

variable "attach_policy" {
  type        = bool
  default     = false
  description = "Controls whether policy should be added to IAM role for Lambda Function"
}

variable "attach_policies" {
  type        = bool
  default     = false
  description = "Controls whether list of policies should be added to IAM role for Lambda Function"
}

variable "number_of_policy_jsons" {
  type        = number
  default     = 0
  description = "Number of policies JSON to attach to IAM role for Lambda Function"
}

variable "number_of_policies" {
  type        = number
  default     = 0
  description = "Number of policies to attach to IAM role for Lambda Function"
}

variable "attach_policy_statements" {
  type        = bool
  default     = false
  description = "Controls whether policy_statements should be added to IAM role for Lambda Function"
}

variable "trusted_entities" {
  type        = any
  default     = []
  description = "List of additional trusted entities for assuming Lambda Function role (trust relationship)"
}

variable "assume_role_policy_statements" {
  type        = any
  default     = {}
  description = "Map of dynamic policy statements for assuming Lambda Function role (trust relationship)"
}

variable "policy_json" {
  type        = string
  default     = null
  description = "An additional policy document as JSON to attach to the Lambda Function role"
}

variable "policy_jsons" {
  type        = list(string)
  default     = []
  description = "List of additional policy documents as JSON to attach to Lambda Function role"
}

variable "policy" {
  type        = string
  default     = null
  description = "An additional policy document ARN to attach to the Lambda Function role"
}

variable "policies" {
  type        = list(string)
  default     = []
  description = "List of policy statements ARN to attach to Lambda Function role"
}

variable "policy_statements" {
  type        = any
  default     = {}
  description = "Map of dynamic policy statements to attach to Lambda Function role"
}

# Build artifact settings
variable "local_existing_package" {
  type        = string
  default     = null
  description = "The absolute path to an existing zip-file to use"
}

variable "s3_existing_package" {
  type        = map(string)
  default     = null
  description = "The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use"
}

variable "source_path" {
  type        = any # string | list(string | map(any))
  default     = null

  description = "The absolute path to a local file or directory containing your Lambda source code"
}

# Layer-specific package variables
variable "layer_local_existing_package" {
  type        = string
  default     = null
  description = "The absolute path to an existing zip-file to use for the layer"
}

variable "layer_s3_existing_package" {
  type        = map(string)
  default     = null
  description = "The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use for the layer"
}

variable "layer_source_path" {
  type        = any
  default     = null
  description = "The absolute path to a local file or"
}