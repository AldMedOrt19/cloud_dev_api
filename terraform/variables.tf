variable "aws_region" {
  description = "Región AWS donde crear EC2 (Aldana)"
  type        = string
  default     = "us-east-2"
}

variable "key_name" {
  description = "Nombre de la key pair existente"
  type        = string
}

variable "repo_url" {
  description = "Repo con el microservicio"
  type        = string
  default     = "https://github.com/EliLuxurious/cloud_dev_api.git"
}

variable "elia_public_host" {
  description = "IP pública o DNS donde corren clima(8001) y temblor(8002)"
  type        = string
  default     = "18.221.212.253"  # cámbialo si usas otro host/DNS
}

variable "instance_type" {
  description = "Tipo de instancia para comportamiento"
  type        = string
  default     = "t3.small"
}

variable "open_to_world" {
  description = "Si true, abre 8000 a todo el mundo; si false, restringe a my_ip_cidr"
  type        = bool
  default     = true
}

variable "my_ip_cidr" {
  description = "Tu IP/32 si open_to_world=false (ej. 1.2.3.4/32)"
  type        = string
  default     = "0.0.0.0/0"
}
