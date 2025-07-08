data "aws_ami" "amazon_linux_2023_arm" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "random_password" "k3s_cluster_token" {
  length  = 32
  special = false
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023_arm.id
  instance_type          = "t4g.nano"
  subnet_id              = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  tags = merge(var.common_tags, {
    Name = "bastion-host"
    Role = "bastion"
  })
}

resource "aws_instance" "k3s_server" {
  ami                    = data.aws_ami.amazon_linux_2023_arm.id
  instance_type          = "t4g.small"
  subnet_id              = values(aws_subnet.private)[0].id
  vpc_security_group_ids = [aws_security_group.k3s_server.id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data/k3s_server_install.sh", {
    k3s_token = random_password.k3s_cluster_token.result
  })

  tags = merge(var.common_tags, {
    Name = "k3s-server"
    Role = "k3s-server"
  })
}

resource "aws_instance" "k3s_agent" {
  ami                    = data.aws_ami.amazon_linux_2023_arm.id
  instance_type          = "t4g.micro"
  subnet_id              = values(aws_subnet.private)[1].id
  vpc_security_group_ids = [aws_security_group.k3s_agent.id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data/k3s_agent_join.sh", {
    k3s_server_private_ip = aws_instance.k3s_server.private_ip,
    k3s_token             = random_password.k3s_cluster_token.result
  })

  tags = merge(var.common_tags, {
    Name = "k3s-agent"
    Role = "k3s-agent"
  })
}