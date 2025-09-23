output "comportamiento_public_ip" {
  description = "IP pública de la EC2 B (Aldana)"
  value       = aws_instance.comportamiento.public_ip
}

output "comportamiento_test_url" {
  description = "URL de prueba del endpoint"
  value       = "http://${aws_instance.comportamiento.public_ip}:8000/comportamiento?city=Lima&date=2025-09-23"
}

output "ssh_hint" {
  value = "ssh -i <RUTA-KEY>.pem debian@${aws_instance.comportamiento.public_ip}  (o admin@)"
}
