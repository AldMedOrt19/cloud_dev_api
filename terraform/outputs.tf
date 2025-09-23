output "comportamiento_public_ip" { value = aws_instance.comportamiento.public_ip }
output "comportamiento_test_url" { value = "http://${aws_instance.comportamiento.public_ip}:8000/comportamiento?city=Lima&date=2025-09-23" }
output "ssh_hint" { value = "ssh -i <KEY>.pem debian@${aws_instance.comportamiento.public_ip} (o admin@)" }
