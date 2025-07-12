
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from user IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
    description = "Allow SSH from my IP"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
    description = "Allow NodePort range from my IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "bastion-sg" })
}

resource "aws_security_group" "nat" {
  name        = "nat-instance-sg"
  description = "Allow traffic from private subnets for NAT"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for s in var.private_subnets : s.cidr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for s in var.private_subnets : s.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "nat-instance-sg" })
}

// SG для K3s Server (без циклических правил)
resource "aws_security_group" "k3s_server" {
  name        = "k3s-server-sg"
  description = "Security group for K3s Server node"
  vpc_id      = aws_vpc.main.id

  // SSH с бастиона
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  // K3s API с бастиона (нециклическая часть правила)
  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "k3s-server-sg" })
}

// SG для K3s Agent (без циклических правил)
resource "aws_security_group" "k3s_agent" {
  name        = "k3s-agent-sg"
  description = "Security group for K3s Agent node"
  vpc_id      = aws_vpc.main.id

  // SSH с бастиона
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "k3s-agent-sg" })
}

// --- Правила для разрыва цикла зависимостей ---

// Разрешить агентам доступ к API сервера (порт 6443)
resource "aws_security_group_rule" "server_api_from_agent" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow K3s agents to access API server"
}

// Разрешить агентам доступ к Kubelet сервера (порт 10250)
resource "aws_security_group_rule" "server_kubelet_from_agent" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow K3s agents to access server Kubelet"
}

// Разрешить Flannel (VXLAN) трафик от агентов к серверу (порт 8472)
resource "aws_security_group_rule" "server_flannel_from_agent" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_agent.id
  security_group_id        = aws_security_group.k3s_server.id
  description              = "Allow Flannel from agent to server"
}

// Разрешить Flannel (VXLAN) трафик от сервера к агентам (порт 8472)
resource "aws_security_group_rule" "agent_flannel_from_server" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_server.id
  security_group_id        = aws_security_group.k3s_agent.id
  description              = "Allow Flannel from server to agent"
}