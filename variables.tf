variable "aws_region" {
  description = "AWS регион для развертывания"
  type        = string
  default     = "eu-west-1"
}

variable "my_ip" {
  description = "Ваш публичный IP адрес для доступа к бастиону"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "Имя вашего пользователя или организации на GitHub"
  type        = string
}

variable "key_name" {
  description = "Имя существующей пары ключей EC2 для доступа к инстансам"
  type        = string
  default     = "bastion-key"
}

variable "common_tags" {
  description = "Общие теги для всех ресурсов"
  type        = map(string)
  default = {
    Project   = "K3s-Cluster-Task"
    Terraform = "true"
    ManagedBy = "Gemini"
  }
}

variable "public_subnets" {
  description = "Публичные подсети"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-subnet-1" = {
      cidr = "10.0.1.0/24"
      az   = "eu-west-1a"
    }
    "public-subnet-2" = {
      cidr = "10.0.2.0/24"
      az   = "eu-west-1b"
    }
  }
}

variable "private_subnets" {
  description = "Приватные подсети"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "private-subnet-1" = {
      cidr = "10.0.101.0/24"
      az   = "eu-west-1a"
    }
    "private-subnet-2" = {
      cidr = "10.0.102.0/24"
      az   = "eu-west-1b"
    }
  }
}
