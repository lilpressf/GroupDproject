output "instance_id" {
  value       = aws_instance.this.id
  description = "EC2 instance ID."
}

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP address."
}

output "ssh_port" {
  value       = local.ssh_port
  description = "SSH port."
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID."
}
