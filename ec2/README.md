# EC2 Instance Terraform Module

A comprehensive Terraform module for deploying and managing AWS EC2 instances with security groups, IAM roles, EBS volumes, and optional Elastic IP assignment.

## Features

- ✅ EC2 instance with customizable configuration
- ✅ Automatic or custom AMI selection
- ✅ Security group creation with ingress/egress rules
- ✅ IAM role and instance profile management
- ✅ Additional EBS volume attachment
- ✅ Elastic IP assignment
- ✅ IMDSv2 enforcement for enhanced security
- ✅ SSM Patch Manager integration
- ✅ Root volume encryption
- ✅ Burstable instance credit specification
- ✅ External network interface support
- ✅ Comprehensive tagging

## Usage

### Basic Example

```hcl
module "ec2_instance" {
  source = "./ec2"

  name      = "my-web-server"
  vpc_id    = "vpc-12345678"
  subnet    = "subnet-12345678"
  key_name  = "my-key-pair"

  instance_type = "t3.medium"
  
  tags = {
    Environment = "production"
    Project     = "web-app"
    Owner       = "devops-team"
  }
}
```

### Advanced Example with Custom Security Rules

```hcl
module "ec2_instance" {
  source = "./ec2"

  name      = "app-server"
  vpc_id    = "vpc-12345678"
  subnet    = "subnet-12345678"
  key_name  = "my-key-pair"

  # Instance configuration
  instance_type = "t3.large"
  ami           = "ami-0c55b159cbfafe1f0"
  ami_owner     = "amazon"

  # Network configuration
  associate_public_ip_address = true
  assign_eip_address          = true

  # Security group configuration
  security_group_enabled = true
  security_group_ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS from anywhere"
    },
    {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
      description = "Allow SSH from internal network"
    }
  ]

  # Storage configuration
  root_volume_type = "gp3"
  root_volume_size = 50
  root_throughput  = 200
  root_iops        = 3000

  # Additional EBS volumes
  ebs_volume_count     = 2
  ebs_volume_size      = 100
  ebs_volume_type      = "gp3"
  ebs_volume_encrypted = true

  # IAM and monitoring
  instance_profile_enabled = true
  monitoring               = true
  
  # Security
  disable_api_termination      = true
  root_block_device_encrypted  = true
  metadata_http_tokens_required = true

  tags = {
    Environment = "production"
    Application = "api-server"
    Backup      = "daily"
  }
}
```

### Example with SSM Session Manager (No SSH Key Required)

```hcl
module "ec2_instance" {
  source = "./ec2"

  name   = "ssm-managed-instance"
  vpc_id = "vpc-12345678"
  subnet = "subnet-12345678"

  instance_type = "t3.micro"

  # Enable SSM for remote access without SSH keys
  instance_profile_enabled    = true
  ssm_patch_manager_enabled   = true
  ssm_patch_manager_s3_log_bucket = "my-patch-logs-bucket"

  # No key_name needed - use SSM Session Manager instead
  
  # Allow SSM traffic (no inbound rules needed)
  security_group_enabled = true
  security_group_egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS for SSM"
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "SSM"
  }
}
```

### Example with External Network Interface

```hcl
resource "aws_network_interface" "external" {
  subnet_id       = "subnet-12345678"
  private_ips     = ["10.0.1.100"]
  security_groups = ["sg-12345678"]

  tags = {
    Name = "external-eni"
  }
}

module "ec2_instance" {
  source = "./ec2"

  name   = "eni-attached-instance"
  vpc_id = "vpc-12345678"
  subnet = "subnet-12345678"

  instance_type = "t3.medium"

  # Use external network interface
  external_network_interface_enabled = true
  external_network_interfaces = [
    {
      device_index          = 0
      network_interface_id  = aws_network_interface.external.id
      delete_on_termination = false
      network_card_index    = 0
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

### Example with User Data

```hcl
module "ec2_instance" {
  source = "./ec2"

  name      = "web-server"
  vpc_id    = "vpc-12345678"
  subnet    = "subnet-12345678"
  key_name  = "my-key-pair"

  instance_type = "t3.small"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Terraform</h1>" > /var/www/html/index.html
  EOF

  user_Data_replace_on_change = true

  tags = {
    Environment = "development"
    Purpose     = "web-server"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `name` | `string` | Name of the EC2 instance. Used in tags and resource naming |
| `vpc_id` | `string` | The ID of the VPC that the instance security group belongs to |
| `subnet` | `string` | VPC Subnet ID the instance is launched in |

### Instance Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance_type` | `string` | `"t2.micro"` | The type of the instance |
| `ami` | `string` | `""` | The AMI to use for the instance. By default uses latest Amazon Linux 2 |
| `ami_owner` | `string` | `""` | Owner of the given AMI |
| `key_name` | `string` | `null` | The key name of an existing EC2 key pair |
| `availability_zone` | `string` | `""` | Availability Zone the instance is launched in |
| `tenancy` | `string` | `"default"` | Tenancy of the instance (default, dedicated, host) |
| `burstable_mode` | `string` | `null` | Enable burstable mode (standard or unlimited) for T2/T3/T4g |

### Network Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `associate_public_ip_address` | `bool` | `false` | Associate a public IP address with the instance |
| `assign_eip_address` | `bool` | `false` | Assign an elastic IP to the instance |
| `private_ip` | `string` | `null` | Private IP address to associate with the instance |
| `secondary_private_ips` | `list(string)` | `[]` | List of secondary private IP addresses |

### Security Group Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `security_group_enabled` | `bool` | `true` | Whether to create default security group for EC2 |
| `security_groups` | `list(string)` | `[]` | A list of security group IDs to associate with EC2 instance |
| `security_group_description` | `string` | `"EC2 Security Group"` | The Security Group Description |
| `security_group_use_name_prefix` | `bool` | `false` | Whether to use name prefix for security group |
| `security_group_ingress_rules` | `list(object)` | `[]` | List of ingress rules |
| `security_group_egress_rules` | `list(object)` | See variables.tf | List of egress rules |

### Storage Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `root_volume_type` | `string` | `"gp2"` | Type of root volume (standard, gp2, gp3, io1, io2) |
| `root_volume_size` | `number` | `10` | Size of the root volume in gigabytes |
| `root_iops` | `number` | `0` | Amount of provisioned IOPS for root volume |
| `root_throughput` | `number` | `0` | Amount of throughput for root volume (gp3 only) |
| `root_block_device_encrypted` | `bool` | `true` | Whether to encrypt the root block device |
| `root_block_device_kms_key_id` | `string` | `null` | KMS key ID for root volume encryption |
| `ebs_volume_count` | `number` | `0` | Count of EBS volumes to attach |
| `ebs_volume_size` | `number` | `10` | Size of additional EBS volumes in gigabytes |
| `ebs_volume_type` | `string` | `"gp2"` | Type of additional EBS volumes |
| `ebs_volume_encrypted` | `bool` | `true` | Whether to encrypt additional EBS volumes |
| `ebs_iops` | `number` | `0` | Amount of provisioned IOPS for EBS volumes |
| `ebs_throughput` | `number` | `0` | Amount of throughput for EBS volumes |
| `kms_key_id` | `string` | `null` | KMS key ID for EBS volume encryption |

### IAM Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance_profile_enabled` | `bool` | `true` | Whether to create an IAM instance profile |
| `instance_profile` | `string` | `""` | A pre-defined profile to attach to the instance |

### Security & Monitoring

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `monitoring` | `bool` | `true` | Enable detailed monitoring |
| `ebs_optimized` | `bool` | `true` | Launch EC2 instance as EBS-optimized |
| `disable_api_stop` | `bool` | `false` | Enable EC2 Instance Stop Protection |
| `disable_api_termination` | `bool` | `false` | Enable EC2 Instance Termination Protection |
| `metadata_http_tokens_required` | `bool` | `true` | Require IMDSv2 (session tokens) |
| `metadata_http_endpoint_enabled` | `bool` | `true` | Enable metadata service |
| `metadata_tags_enabled` | `bool` | `false` | Enable tags in metadata service |
| `metadata_http_put_response_hop_limit` | `number` | `2` | HTTP PUT response hop limit |

### SSM Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ssm_patch_manager_enabled` | `bool` | `false` | Enable SSM Patch Manager |
| `ssm_patch_manager_iam_policy_arn` | `string` | `null` | IAM policy ARN for Patch Manager |
| `ssm_patch_manager_s3_log_bucket` | `string` | `null` | S3 bucket for patch logs |

### Tags

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | A map of tags to assign to resources |
| `volume_tags_enabled` | `bool` | `true` | Whether to copy instance tags to volumes |

## Outputs

### Instance Outputs

| Name | Description |
|------|-------------|
| `instance_id` | The ID of the EC2 instance |
| `instance_arn` | The ARN of the EC2 instance |
| `instance_state` | The state of the instance |
| `instance_type` | The type of the instance |
| `availability_zone` | The availability zone of the instance |
| `private_ip` | The private IP address |
| `private_dns` | The private DNS name |
| `public_ip` | The public IP address (if applicable) |
| `public_dns` | The public DNS name |
| `primary_network_interface_id` | The ID of the primary network interface |
| `subnet_id` | The VPC subnet ID |
| `ami_id` | The AMI ID used for the instance |

### Security Group Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | The ID of the created security group |
| `security_group_arn` | The ARN of the created security group |
| `security_group_name` | The name of the created security group |
| `security_group_ids` | List of all security group IDs attached |

### IAM Outputs

| Name | Description |
|------|-------------|
| `iam_role_name` | The name of the IAM role |
| `iam_role_arn` | The ARN of the IAM role |
| `iam_instance_profile_name` | The name of the IAM instance profile |
| `iam_instance_profile_arn` | The ARN of the IAM instance profile |

### Storage Outputs

| Name | Description |
|------|-------------|
| `ebs_volume_ids` | List of IDs of additional EBS volumes |
| `ebs_volume_arns` | List of ARNs of additional EBS volumes |
| `root_volume_id` | The ID of the root volume |

### Elastic IP Outputs

| Name | Description |
|------|-------------|
| `eip_id` | The ID of the Elastic IP |
| `eip_public_ip` | The Elastic IP address |
| `eip_allocation_id` | The allocation ID of the Elastic IP |

## Security Best Practices

1. **IMDSv2**: This module enforces IMDSv2 by default (`metadata_http_tokens_required = true`)
2. **Encryption**: Root and EBS volumes are encrypted by default
3. **SSH Keys**: Store private keys securely outside version control. Consider using SSM Session Manager instead
4. **Security Groups**: Follow the principle of least privilege when defining ingress rules
5. **Termination Protection**: Enable for production instances (`disable_api_termination = true`)
6. **Monitoring**: Detailed monitoring is enabled by default for better observability

## Notes

- The module automatically selects the latest Amazon Linux 2 AMI if no AMI is specified
- Security groups are created only if `security_group_enabled = true` and no external security groups are provided
- IAM roles and instance profiles are created automatically unless you provide a pre-existing profile
- EBS volumes are attached sequentially using device names from `/dev/xvdb` onwards

## License

See LICENSE file in the repository root.

## Authors

Managed by your DevOps team.
