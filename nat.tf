resource "aws_instance" "nat" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2023 AMI
  instance_type               = "t4g.micro" # ~$3.5/month
  subnet_id                   = values(aws_subnet.public)[0].id # Place in public subnet
  vpc_security_group_ids      = [aws_security_group.nat.id]
  associate_public_ip_address = true
  source_dest_check           = false # Required for NAT functionality

  user_data = <<-EOF
              #!/bin/bash
              echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
              sudo sysctl -p
              sudo iptables -t nat -A POSTROUTING -o ens5 -s ${var.vpc_cidr} -j MASQUERADE
              EOF

  tags = merge(var.common_tags, { 
    Name = "nat-instance"
    Role = "nat"
  })
}

# Update private route table to use NAT instance
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.nat.id
}