terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "huntertigerx3-terraform-state-bucket"
    key          = "global/s3/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

# Resource to generate a secure K3s cluster token
resource "random_password" "k3s_cluster_token" {
  length  = 32
  special = false # K3s token typically doesn't require special characters [2, 3]
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id # Amazon Linux 2023 AMI [4]
  instance_type               = "t3.micro"
  subnet_id                   = values(aws_subnet.public)[0].id # Place in first public subnet [4]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = "my-bastion-key"

  tags = merge(var.common_tags, {
    Name = "bastion-host"
    Role = "bastion"
  })
}

resource "aws_instance" "k3s_server" {
  # IMPORTANT: Amazon Linux 2023 has known compatibility issues with K3s.
  # Consider using Amazon Linux 2 or Ubuntu LTS for stability. [5, 6]
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.small" # Recommended: t3.small or t3.medium for server [7]
  subnet_id                   = values(aws_subnet.private)[0].id # Place in first private subnet [4]
  vpc_security_group_ids      = [aws_security_group.k3s_server.id]
  associate_public_ip_address = false # Server in private subnet
  key_name                    = "my-bastion-key"

  user_data = templatefile("${path.module}/user_data/k3s_server_install.sh", {
    k3s_token = random_password.k3s_cluster_token.result
  })

  tags = merge(var.common_tags, {
    Name = "k3s-server"
    Role = "k3s-server"
  })
}

resource "aws_instance" "k3s_agent" {
  # IMPORTANT: Amazon Linux 2023 has known compatibility issues with K3s.
  # Consider using Amazon Linux 2 or Ubuntu LTS for stability. [5, 6]
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro" # Free tier eligible, suitable for agent [8, 9]
  subnet_id                   = values(aws_subnet.private)[1].id # Place in second private subnet [4]
  vpc_security_group_ids      = [aws_security_group.k3s_agent.id]
  associate_public_ip_address = false # Agent in private subnet
  key_name                    = "my-bastion-key"

  user_data = templatefile("${path.module}/user_data/k3s_agent_join.sh", {
    k3s_server_private_ip = aws_instance.k3s_server.private_ip,
    k3s_token             = random_password.k3s_cluster_token.result
  })

  tags = merge(var.common_tags, {
    Name = "k3s-agent"
    Role = "k3s-agent"
  })
}
