# Bastion host security group
resource "aws_security_group" "bastion" {
  name        = "bastion-host"
  description = "Allow SSH access to bastion host and outbound to K3s nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production [2]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows all outbound traffic, including SSH to K3s nodes
  }

  tags = merge(var.common_tags, { Name = "bastion-host-sg" })
}



# K3s Server security group
resource "aws_security_group" "k3s_server" {
  name        = "k3s-server-sg"
  description = "Security group for K3s Server node"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Allow K3s API/Supervisor from bastion"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Allow SSH from bastion"
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
    description = "Allow embedded etcd (HA) from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "k3s-server-sg" })
}

# K3s Agent security group
resource "aws_security_group" "k3s_agent" {
  name        = "k3s-agent-sg"
  description = "Security group for K3s Agent node"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Allow SSH from bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "k3s-agent-sg" })
}

# Separate security group rules to avoid circular dependency
resource "aws_security_group_rule" "k3s_server_from_agent_api" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow K3s API from agents"
}

resource "aws_security_group_rule" "k3s_server_from_agent_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow Kubelet metrics from agents"
}

resource "aws_security_group_rule" "k3s_server_from_agent_flannel" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow Flannel VXLAN from agents"
}

resource "aws_security_group_rule" "k3s_agent_from_server_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_server.id
  security_group_id        = aws_security_group.k3s_agent.id
  description              = "Allow Kubelet metrics from server"
}

resource "aws_security_group_rule" "k3s_agent_from_server_flannel" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_server.id
  security_group_id        = aws_security_group.k3s_agent.id
  description              = "Allow Flannel VXLAN from server"
}

resource "aws_security_group_rule" "k3s_server_from_bastion_api" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow K3s API access from bastion"
}