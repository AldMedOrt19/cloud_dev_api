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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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
  ami                         = data.aws_ami.ubuntu.id
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
    # Corregido: Se instala 'docker-compose' en lugar de 'docker-compose-plugin'
    retry apt-get install -y --no-install-recommends docker.io docker-compose git

    systemctl enable --now docker

    # En Ubuntu, el usuario por defecto es 'ubuntu'
    USERNAME="ubuntu"

    usermod -aG docker $USERNAME

    # clonar repo en HOME del usuario
    su - $USERNAME -c "rm -rf ~/cloud_dev_api && git clone ${var.repo_url} ~/cloud_dev_api"

    # docker-compose.yml SOLO para comportamiento
    cat >/home/$USERNAME/cloud_dev_api/comportamiento/docker-compose.yml << YAML
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

    chown -R $USERNAME:$USERNAME /home/$USERNAME/cloud_dev_api

    # build + up como el usuario normal (no root)
    su - $USERNAME -c "cd ~/cloud_dev_api/comportamiento && docker-compose up -d --build"
  EOF

  tags = {
    Name = "aldana-comportamiento"
  }
}
