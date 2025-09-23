variable "aws_region"       { default = "us-east-2" }
variable "key_name"         { description = "Nombre de la key pair existente" }
variable "repo_url"         { default = "https://github.com/EliLuxurious/cloud_dev_api.git" }
variable "elia_public_host" { default = "18.221.212.253" } # IP/DNS de tu EC2 A
variable "instance_type"    { default = "t3.small" }
variable "open_to_world"    { default = true }
variable "my_ip_cidr"       { default = "0.0.0.0/0" }
