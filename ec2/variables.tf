variable "associate_public_ip_address" {
  type = bool
  default = false
  description = "Associate a public IP address with the instance"
}

variable "assign_eip_address" {
  type = bool
  default = false
  description = "Assign an elastic IP to the instance"
}

variable "user_data" {
  type = string
  default = null
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; use `user_data_base64` instead"
}

variable "user_data_base64" {
  type = string
  default = null
  description = "Can be used instead of `user_data` to pass base64-encoded binary data directly. Use this instead of `user_data` whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption"
}

variable "user_data_replace_on_change" {
  type = bool
  default = false
  description = "when used in combination with user_data or user_data_base64 will trigger a destroy and recreate when set to true"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "The type of the instance"
}

variable "burstable_mode" {
  type = string
  default = null
  description = "Enable burstable mode for the instance. Can be standard or unlimited. Applicable only for T2/T3/T4g instance types"
}

variable "vpc_id" {
  type = string
  description = "The ID of the vpc that the instance security group belongs to"
}

variable "security_group_enabled" {
  type = bool
  default = true
  description = "Whether to create default security group for EC2."
}

variable "security_groups" {
  description = "A list of security group IDs to associate with EC2 instance"
  type = list(string)
  default = []
}

variable "security_group_description" {
  type = string
  default = "EC2 Security Group"
  description = "The Security Group Description"
}

variable "security_group_use_name_prefix" {
  type = bool
  default = false
  description = "Whether to create a default security group with unique name beginning eith the normalized prefix"
}

variable "security_group_ingress_rules" {
  type = list(object({
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    description                  = optional(string)
    tags                         = optional(map(string))
  }))
  default     = []
  description = <<-EOT
  A list of security group ingress rules.
  Each rule should specify from_port, to_port, ip_protocol, and one of: cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id.
  Compatible with aws_vpc_security_group_ingress_rule resource.
  EOT
}

variable "security_group_egress_rules" {
  type = list(object({
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    description                  = optional(string)
    tags                         = optional(map(string))
  }))
  default = [
    {
      from_port   = 0
      to_port     = 65535
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]
  description = <<-EOT
  A list of security group egress rules.
  Each rule should specify from_port, to_port, ip_protocol, and one of: cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id.
  Compatible with aws_vpc_security_group_egress_rule resource.
  EOT
}

variable "subnet" {
  type = string
  description = "VPC Subnet ID the instance is launched in"
}

variable "region" {
  type = string
  default = ""
  description = "AWS Region the instance in launched in"
}

variable "availability_zone" {
  type = string
  default = ""
  description = "Availability Zone the instance is launched in. If not set, will be launched in the first AZ of the region"
}

variable "ami" {
  type = string
  default = ""
  description = "The AMI to use for the instance. By default it is the AMI provided by Amazon"
}

variable "ami_owner" {
  type = string
  description = "Owner of the given AMI (ignored if `ami` unset, required if set)"
  default = ""
}

variable "ebs_optimized" {
  type = bool
  default = true
  description = "Launched EC2 instance will be EBS-optimized"
}

variable "disable_api_stop" {
  type = bool
  default = false
  description = "Enable EC2 Instance Stop Protection"
}

variable "disable_api_termination" {
  type = bool
  default = false
  description = "Enable EC2 Instance Termination Protection"
}

variable "monitoring" {
  type = bool
  default = true
  description = "Launched EC2 instance will have detailed monitoring enabled"
}

variable "private_ip" {
  type = string
  default = null
  description = "Private IP address to associate with the instance in the VPC"
}

variable "secondary_private_ips" {
  type = list(string)
  default = []
  description = "List of secondary private IP addresses to associate with the instance in the vpc"
}

variable "root_volume_type" {
  type = string
  description = "Tyoe of root volume. Can be standard, gp2, gp3, io1 or io2"
  default = "gp2"
}

variable "root_volume_size" {
  type = number
  default = 10
  description = "Size of the root volume in gigabytes"
}

variable "root_iops" {
  type = number
  default = 0
  description = "Amount of provisioned IOPs. This must be set if root_volume_type is set of `io1` `io2` or `gp3`."
}

variable "root_throughput" {
  type = number
  default = 0
  description = "Amount of throughput. This must be set if root_volume_type is set to `gp3`"
}

variable "ebs_device_name" {
  type = list(string)
  description = "Name of the EBS device to mount"
  default     = ["/dev/xvdb", "/dev/xvdc", "/dev/xvdd", "/dev/xvde", "/dev/xvdf", "/dev/xvdg", "/dev/xvdh", "/dev/xvdi", "/dev/xvdj", "/dev/xvdk", "/dev/xvdl", "/dev/xvdm", "/dev/xvdn", "/dev/xvdo", "/dev/xvdp", "/dev/xvdq", "/dev/xvdr", "/dev/xvds", "/dev/xvdt", "/dev/xvdu", "/dev/xvdv", "/dev/xvdw", "/dev/xvdx", "/dev/xvdy", "/dev/xvdz"]
}

variable "ebs_volume_type" {
  type = string
  default = "gp2"
  description = "The type of the additional EBS volumes. Can be standard, gp2, gp3, io1 or io2"
}

variable "ebs_volume_size" {
  type = number
  default = 10
  description = "Size of the additional EBS volumes in gigabytes"
}

variable "ebs_volume_encrypted" {
  type = bool
  default = true
  description = "Whether to encrypt the additional EBS volumes"
}

variable "ebs_iops" {
  type        = number
  description = "Amount of provisioned IOPS. This must be set with a volume_type of `io1`, `io2` or `gp3`"
  default     = 0
}

variable "ebs_throughput" {
  type        = number
  description = "Amount of throughput. This must be set if volume_type is set to `gp3`"
  default     = 0
}

variable "ebs_volume_count" {
  type        = number
  description = "Count of EBS volumes that will be attached to the instance"
  default     = 0
}

variable "delete_on_termination" {
  type        = bool
  description = "Whether the volume should be destroyed on instance termination"
  default     = true
}

variable "instance_profile" {
  type        = string
  description = "A pre-defined profile to attach to the instance (default is to build our own)"
  default     = ""
}


variable "instance_profile_enabled" {
  type        = bool
  default     = true
  description = "Whether an IAM instance profile is created to pass a role to an Amazon EC2 instance when the instance starts"
}

variable "instance_initiated_shutdown_behavior" {
  type        = string
  description = "Specifies whether an instance stops or terminates when you initiate shutdown from the instance. Can be one of 'stop' or 'terminate'."
  default     = null
}

variable "root_block_device_encrypted" {
  type        = bool
  default     = true
  description = "Whether to encrypt the root block device"
}

variable "root_block_device_kms_key_id" {
  type        = string
  default     = null
  description = "KMS key ID used to encrypt EBS volume. When specifying root_block_device_kms_key_id, root_block_device_encrypted needs to be set to true"
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = true
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2."
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Whether the metadata service is available"
}

variable "metadata_tags_enabled" {
  type        = bool
  default     = false
  description = "Whether the tags are enabled in the metadata service."
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 2
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS key ID used to encrypt EBS volume. When specifying kms_key_id, ebs_volume_encrypted needs to be set to true"
}

variable "volume_tags_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to copy instance tags to root and EBS volumes"
}

variable "ssm_patch_manager_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable SSM Patch manager"
}

variable "ssm_patch_manager_iam_policy_arn" {
  type        = string
  default     = null
  description = "IAM policy ARN to allow Patch Manager to manage the instance. If not provided, `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` will be used"
}

variable "ssm_patch_manager_s3_log_bucket" {
  type        = string
  default     = null
  description = "The name of the s3 bucket to export the patch log to"
}

variable "tenancy" {
  type        = string
  default     = "default"
  description = "Tenancy of the instance (if the instance is running in a VPC). An instance with a tenancy of 'dedicated' runs on single-tenant hardware. The 'host' tenancy is not supported for the import-instance command. Valid values are 'default', 'dedicated', and 'host'."
  validation {
    condition     = contains(["default", "dedicated", "host"], lower(var.tenancy))
    error_message = "Tenancy field can only be one of default, dedicated, host."
  }
}

variable "external_network_interface_enabled" {
  type        = bool
  default     = false
  description = "Wheter to attach an external ENI as the eth0 interface for the instance. Any change to the interface will force instance recreation."
}

variable "external_network_interfaces" {
  type = list(object({
    delete_on_termination = bool
    device_index          = number
    network_card_index    = number
    network_interface_id  = string
  }))
  description = "The external interface definitions to attach to the instances. This depends on the instance type"
  default     = null
}

variable "force_detach_ebs" {
  type        = bool
  default     = false
  description = "force the volume/s to detach from the instance."
}

variable "stop_ec2_before_detaching_vol" {
  type        = bool
  default     = false
  description = "Set this to true to ensure that the target instance is stopped before trying to detach the volumes."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to assign to the EC2 instance and associated resources"
}

variable "name" {
  type        = string
  description = "Name of the EC2 instance. Will be used in tags and resource naming"
}

variable "key_name" {
  type        = string
  default     = null
  description = "The key name of an existing EC2 key pair to use for the instance. The key pair must already exist in AWS. The private key (.pem file) should be stored securely outside of version control. If not specified, no key pair will be associated. Consider using AWS Systems Manager Session Manager as an alternative to SSH keys."
}

variable "source_dest_check" {
  type        = bool
  default     = true
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs. Set to false for NAT instances."
}
