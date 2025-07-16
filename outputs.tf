output "bastion_public_ip" {
  description = "Публичный IP адрес Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "nat_instance_public_ip" {
  description = "Публичный IP адрес NAT Instance"
  value       = aws_instance.nat.public_ip
}

output "k3s_server_private_ip" {
  description = "Приватный IP адрес K3s Server"
  value       = aws_instance.k3s_server.private_ip
}

output "k3s_agent_private_ip" {
  description = "Приватный IP адрес K3s Agent"
  value       = aws_instance.k3s_agent.private_ip
}



output "kubectl_access_instructions" {
  description = "Инструкции для доступа к кластеру K3s"
  value = <<-EOT
    ####################################################################
    # Инструкции для доступа к кластеру K3s с вашего локального ПК
    ####################################################################

    1. Убедитесь, что ваш SSH агент имеет ваш ключ:
       ssh-add ~/.ssh/your-key.pem

    2. Подключитесь к бастиону:
       ssh ec2-user@${aws_instance.bastion.public_ip}

    3. С бастиона, скопируйте kubeconfig с K3s сервера:
       ssh ec2-user@${aws_instance.k3s_server.private_ip} "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s.yaml

    4. В файле k3s.yaml замените '127.0.0.1' на приватный IP K3s сервера:
       sed -i 's/127.0.0.1/${aws_instance.k3s_server.private_ip}/' k3s.yaml

    5. Проверьте доступ к кластеру с бастиона:
       export KUBECONFIG=$PWD/k3s.yaml
       kubectl get nodes

    ####################################################################
    # (Опционально) Доступ к кластеру напрямую с локального ПК
    ####################################################################

    1. Скопируйте файл k3s.yaml с бастиона на ваш локальный ПК.
       scp ec2-user@${aws_instance.bastion.public_ip}:~/k3s.yaml .

    2. На локальном ПК, настройте `ProxyCommand` в вашем SSH конфиге (~/.ssh/config):
       Host k3s-server
         HostName ${aws_instance.k3s_server.private_ip}
         User ec2-user
         ProxyJump ec2-user@${aws_instance.bastion.public_ip}

    3. В локальном файле k3s.yaml, измените 'server' на 'https://k3s-server:6443'.

    4. Проверьте доступ:
       export KUBECONFIG=$PWD/k3s.yaml
       kubectl get nodes
  EOT
}
