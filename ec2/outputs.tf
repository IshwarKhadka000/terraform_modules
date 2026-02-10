###############################################################################
# EC2 Instance Outputs
###############################################################################

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_state" {
  description = "The state of the instance"
  value       = aws_instance.this.instance_state
}

output "instance_type" {
  description = "The type of the instance"
  value       = aws_instance.this.instance_type
}

output "availability_zone" {
  description = "The availability zone of the instance"
  value       = aws_instance.this.availability_zone
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = aws_instance.this.private_ip
}

output "private_dns" {
  description = "The private DNS name assigned to the instance"
  value       = aws_instance.this.private_dns
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "The public DNS name assigned to the instance"
  value       = aws_instance.this.public_dns
}

output "primary_network_interface_id" {
  description = "The ID of the instance's primary network interface"
  value       = aws_instance.this.primary_network_interface_id
}

output "subnet_id" {
  description = "The VPC subnet ID"
  value       = aws_instance.this.subnet_id
}

###############################################################################
# Security Group Outputs
###############################################################################

output "security_group_id" {
  description = "The ID of the created security group (if created)"
  value       = local.create_security_group ? aws_security_group.default[0].id : null
}

output "security_group_arn" {
  description = "The ARN of the created security group (if created)"
  value       = local.create_security_group ? aws_security_group.default[0].arn : null
}

output "security_group_name" {
  description = "The name of the created security group (if created)"
  value       = local.create_security_group ? aws_security_group.default[0].name : null
}

output "security_group_ids" {
  description = "List of all security group IDs attached to the instance"
  value       = local.security_group_ids
}

###############################################################################
# IAM Outputs
###############################################################################

output "iam_role_name" {
  description = "The name of the IAM role (if created)"
  value       = var.instance_profile_enabled && var.instance_profile == "" ? aws_iam_role.default[0].name : null
}

output "iam_role_arn" {
  description = "The ARN of the IAM role (if created)"
  value       = var.instance_profile_enabled && var.instance_profile == "" ? aws_iam_role.default[0].arn : null
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = var.instance_profile != "" ? var.instance_profile : (var.instance_profile_enabled ? aws_iam_instance_profile.default[0].name : null)
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile (if created)"
  value       = var.instance_profile_enabled && var.instance_profile == "" ? aws_iam_instance_profile.default[0].arn : null
}

###############################################################################
# EBS Volume Outputs
###############################################################################

output "ebs_volume_ids" {
  description = "List of IDs of additional EBS volumes"
  value       = aws_ebs_volume.default[*].id
}

output "ebs_volume_arns" {
  description = "List of ARNs of additional EBS volumes"
  value       = aws_ebs_volume.default[*].arn
}

output "root_volume_id" {
  description = "The ID of the root volume"
  value       = aws_instance.this.root_block_device[0].volume_id
}

###############################################################################
# Elastic IP Outputs
###############################################################################

output "eip_id" {
  description = "The ID of the Elastic IP (if assigned)"
  value       = var.assign_eip_address ? aws_eip.default[0].id : null
}

output "eip_public_ip" {
  description = "The Elastic IP address (if assigned)"
  value       = var.assign_eip_address ? aws_eip.default[0].public_ip : null
}

output "eip_allocation_id" {
  description = "The allocation ID of the Elastic IP (if assigned)"
  value       = var.assign_eip_address ? aws_eip.default[0].allocation_id : null
}

###############################################################################
# Additional Outputs
###############################################################################

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = local.ami_id
}

output "tags" {
  description = "The tags applied to the instance"
  value       = aws_instance.this.tags
}
