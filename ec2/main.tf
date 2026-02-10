###############################################################################
# EC2 Instance Module
# This module creates an EC2 instance with optional security groups, IAM roles,
# EBS volumes, and Elastic IP assignment.

###############################################################################
# Data Sources
###############################################################################

# Get the latest Amazon Linux 2 AMI if no AMI is specified
data "aws_ami" "amazon_linux" {
  count       = var.ami == "" ? 1 : 0
  most_recent = true
  owners      = [var.ami_owner != "" ? var.ami_owner : "amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current region if not specified
data "aws_region" "current" {}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# Local Variables
###############################################################################

locals {
  region            = var.region != "" ? var.region : data.aws_region.current.name
  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
  ami_id            = var.ami != "" ? var.ami : data.aws_ami.amazon_linux[0].id

  # Merge default tags with user-provided tags
  common_tags = merge(
    {
      Name        = var.name
      ManagedBy   = "Terraform"
      Environment = lookup(var.tags, "Environment", "unknown")
    },
    var.tags
  )

  # Determine if we should create a security group
  create_security_group = var.security_group_enabled && length(var.security_groups) == 0

  # Combine created and provided security groups
  security_group_ids = concat(
    local.create_security_group ? [aws_security_group.default[0].id] : [],
    var.security_groups
  )
}

###############################################################################
# Security Group
###############################################################################

# Create a default security group if enabled and no external SGs provided
resource "aws_security_group" "default" {
  count = local.create_security_group ? 1 : 0

  name_prefix = var.security_group_use_name_prefix ? "${var.name}-" : null
  name        = var.security_group_use_name_prefix ? null : "${var.name}-sg"
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.create_security_group ? { for idx, rule in var.security_group_ingress_rules : idx => rule } : {}

  security_group_id = aws_security_group.default[0].id

  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  description                  = lookup(each.value, "description", null)

  tags = merge(
    local.common_tags,
    lookup(each.value, "tags", {})
  )
}

# Security Group Egress Rules
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.create_security_group ? { for idx, rule in var.security_group_egress_rules : idx => rule } : {}

  security_group_id = aws_security_group.default[0].id

  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
  description                  = lookup(each.value, "description", null)

  tags = merge(
    local.common_tags,
    lookup(each.value, "tags", {})
  )
}

###############################################################################
# IAM Role and Instance Profile
###############################################################################

# IAM role for the EC2 instance
resource "aws_iam_role" "default" {
  count = var.instance_profile_enabled && var.instance_profile == "" ? 1 : 0

  name_prefix = "${var.name}-"
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach SSM policy if SSM Patch Manager is enabled
resource "aws_iam_role_policy_attachment" "ssm_patch_manager" {
  count = var.instance_profile_enabled && var.instance_profile == "" && var.ssm_patch_manager_enabled ? 1 : 0

  role       = aws_iam_role.default[0].name
  policy_arn = var.ssm_patch_manager_iam_policy_arn != null ? var.ssm_patch_manager_iam_policy_arn : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "default" {
  count = var.instance_profile_enabled && var.instance_profile == "" ? 1 : 0

  name_prefix = "${var.name}-"
  role        = aws_iam_role.default[0].name

  tags = local.common_tags
}

###############################################################################
# EC2 Instance
###############################################################################

resource "aws_instance" "this" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Network configuration
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.external_network_interface_enabled ? null : local.security_group_ids
  associate_public_ip_address = var.external_network_interface_enabled ? null : var.associate_public_ip_address
  private_ip                  = var.external_network_interface_enabled ? null : var.private_ip
  secondary_private_ips       = var.external_network_interface_enabled ? null : var.secondary_private_ips
  source_dest_check           = var.source_dest_check

  # External network interfaces (if enabled)
  dynamic "network_interface" {
    for_each = var.external_network_interface_enabled && var.external_network_interfaces != null ? var.external_network_interfaces : []
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = network_interface.value.network_interface_id
      delete_on_termination = network_interface.value.delete_on_termination
      network_card_index    = network_interface.value.network_card_index
    }
  }

  # IAM instance profile
  iam_instance_profile = var.instance_profile != "" ? var.instance_profile : (
    var.instance_profile_enabled ? aws_iam_instance_profile.default[0].name : null
  )

  # User data
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  # Instance configuration
  availability_zone = local.availability_zone
  tenancy           = var.tenancy
  ebs_optimized     = var.ebs_optimized
  disable_api_stop                     = var.disable_api_stop
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  monitoring                           = var.monitoring

  # Credit specification for burstable instances (T2/T3/T4g)
  dynamic "credit_specification" {
    for_each = var.burstable_mode != null ? [1] : []
    content {
      cpu_credits = var.burstable_mode
    }
  }

  # Root block device
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_iops > 0 ? var.root_iops : null
    throughput            = var.root_throughput > 0 ? var.root_throughput : null
    encrypted             = var.root_block_device_encrypted
    kms_key_id            = var.root_block_device_kms_key_id
    delete_on_termination = true
    tags = var.volume_tags_enabled ? merge(
      local.common_tags,
      {
        Name = "${var.name}-root"
      }
    ) : null
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_tags_enabled ? "enabled" : "disabled"
  }

  # Tags
  tags = local.common_tags
  volume_tags = var.volume_tags_enabled ? merge(
    local.common_tags,
    {
      Name = "${var.name}-volume"
    }
  ) : null

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      user_data_base64
    ]
  }
}

###############################################################################
# Additional EBS Volumes
###############################################################################

resource "aws_ebs_volume" "default" {
  count = var.ebs_volume_count

  availability_zone = local.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  iops              = var.ebs_iops > 0 ? var.ebs_iops : null
  throughput        = var.ebs_throughput > 0 ? var.ebs_throughput : null
  encrypted         = var.ebs_volume_encrypted
  kms_key_id        = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-ebs-${count.index + 1}"
    }
  )
}

resource "aws_volume_attachment" "default" {
  count = var.ebs_volume_count

  device_name  = var.ebs_device_name[count.index]
  volume_id    = aws_ebs_volume.default[count.index].id
  instance_id  = aws_instance.this.id
  force_detach = var.force_detach_ebs
  stop_instance_before_detaching = var.stop_ec2_before_detaching_vol

  depends_on = [aws_instance.this]
}

###############################################################################
# Elastic IP
###############################################################################

resource "aws_eip" "default" {
  count = var.assign_eip_address ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-eip"
    }
  )

  depends_on = [aws_instance.this]
}

###############################################################################
# SSM Association for Patch Manager
###############################################################################

resource "aws_ssm_association" "patch_manager" {
  count = var.ssm_patch_manager_enabled ? 1 : 0

  name = "AWS-RunPatchBaseline"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  parameters = {
    Operation = "Install"
  }

  dynamic "output_location" {
    for_each = var.ssm_patch_manager_s3_log_bucket != null ? [1] : []
    content {
      s3_bucket_name = var.ssm_patch_manager_s3_log_bucket
      s3_key_prefix  = "patch-logs/${var.name}"
    }
  }
}
