terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC por defecto
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter { name = "vpc-id" values = [data.aws_vpc.default.id] }
}

# AMI Debian 13 (oficial)
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]
  filter { name = "name" values = ["debian-13-amd64-*"] }
}

# SG para comportamiento (8000) + SSH
resource "aws_security_group" "comportamiento_sg" {
  name        = "comportamiento-sg"
  description = "Permite SSH y HTTP(8000) para comportamiento"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.open_to_world ? "0.0.0.0/0" : var.my_ip_cidr]
  }

  ingress {
    description = "comportamiento"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.open_to_world ? "0.0.0.0/0" : var.my_ip_cidr]
  }

  egress {
    description = "salida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 B (Aldana): clona repo y levanta comportamiento
resource "aws_instance" "comportamiento" {
  ami                         = data.aws_ami.debian.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.comportamiento_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update
    apt-get install -y docker.io docker-compose-plugin git

    systemctl enable --now docker

    # usuario por defecto en Debian AWS suele ser 'debian'; si existe 'admin' úsalo
    USERNAME="debian"
    id admin && USERNAME="admin" || true
    usermod -aG docker ${USERNAME}

    su - ${USERNAME} -c "rm -rf ~/cloud_dev_api && git clone ${var.repo_url} ~/cloud_dev_api"

    cat >/home/${USERNAME}/cloud_dev_api/comportamiento/docker-compose.yml << 'YAML'
    version: "3.9"
    services:
      comportamiento:
        build: .
        container_name: comportamiento
        ports:
          - "8000:80"
        environment:
          CLIMA_API_BASE: "http://${var.elia_public_host}:8001/clima"
          TEMBLOR_API_BASE: "http://${var.elia_public_host}:8002/temblor"
        restart: unless-stopped
    YAML

    su - ${USERNAME} -c "cd ~/cloud_dev_api/comportamiento && docker compose up -d --build"
  EOF

  tags = { Name = "aldana-comportamiento" }
}
