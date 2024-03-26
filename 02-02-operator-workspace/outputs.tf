output "secret_private_ec2_ip" {
  description = "The Private IPv4 address of the EC2 target provision by the Operator:"
  value       = aws_instance.main.private_ip
}

output "private-ec2_key" {
  description = "PEM:"
  value       = tls_private_key.private-ec2_rsa_4096_key.private_key_pem
  sensitive   = true
}

output "aws_creds_op_key" {
  description = "Operator key verification"
  value       = data.vault_aws_access_credentials.creds.access_key
  sensitive   = true
}
