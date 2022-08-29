output "public_ip" {
  description = "Public instance IP"
  value       = aws_instance.web_ebs.*.public_ip
}