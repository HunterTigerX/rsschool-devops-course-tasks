#!/bin/bash
sudo yum update -y
sudo yum install -y iptables-services
sudo systemctl enable iptables
sudo systemctl start iptables
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ip-forward.conf
sudo sysctl -p
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo service iptables save