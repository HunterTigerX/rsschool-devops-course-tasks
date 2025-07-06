resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.common_tags, { Name = "k3s-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "k3s-igw" })
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = each.key, Tier = "public" })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = merge(var.common_tags, { Name = each.key, Tier = "private" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.common_tags, { Name = "k3s-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux_2023_arm.id
  instance_type               = "t4g.nano"
  subnet_id                   = values(aws_subnet.public)[0].id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = var.key_name
  user_data                   = file("${path.module}/user_data/nat_setup.sh")

  tags = merge(var.common_tags, {
    Name = "nat-instance"
    Role = "nat"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block             = "0.0.0.0/0"
    // ИСПРАВЛЕНО: Используем ID сетевого интерфейса, а не ID инстанса
    network_interface_id   = aws_instance.nat.primary_network_interface_id
  }
  tags = merge(var.common_tags, { Name = "k3s-private-rt" })
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}