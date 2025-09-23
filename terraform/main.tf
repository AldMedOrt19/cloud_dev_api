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

# Subnets de la VPC por defecto
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# AMI Debian 13 oficial (más reciente)
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }
}

# SG para comportamiento (22 y 8000)
resource "aws_security_group" "comportamiento_sg" {
  name        = "comportamiento-sg"
  description = "Permite SSH y HTTP(8000)"
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
    description = "all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 B (Aldana) que despliega 'comportamiento'
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

    export DEBIAN_FRONTEND=noninteractive

    # función de retry para apt
    retry() {
      for i in 1 2 3; do
        "$@" && return 0 || sleep 5
      done
      return 1
    }

    retry apt-get update
    retry apt-get install -y --no-install-recommends docker.io docker-compose-plugin git

    systemctl enable --now docker

    # Usuario por defecto (si existe admin, úsalo; si no, debian)
    USERNAME="debian"; id admin >/dev/null 2>&1 && USERNAME="admin" || true

    usermod -aG docker $${USERNAME}

    # clonar repo en HOME del usuario
    su - $${USERNAME} -c "rm -rf ~/cloud_dev_api && git clone ${var.repo_url} ~/cloud_dev_api"

    # docker-compose.yml SOLO para comportamiento
    cat >/home/$${USERNAME}/cloud_dev_api/comportamiento/docker-compose.yml << 'YAML'
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

    chown -R $${USERNAME}:$${USERNAME} /home/$${USERNAME}/cloud_dev_api

    # build + up como el usuario normal (no root)
    su - $${USERNAME} -c "cd ~/cloud_dev_api/comportamiento && docker compose up -d --build"
  EOF

  tags = {
    Name = "aldana-comportamiento"
  }
}

# (Opcional) Elastic IP
# resource "aws_eip" "comportamiento_eip" {
#   domain   = "vpc"
#   instance = aws_instance.comportamiento.id
#   tags = { Name = "aldana-comportamiento-eip" }
# }