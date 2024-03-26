output "hcp-b-pki-worker_ip" {
  description = "HCP Boundary PKI Worker Public IP:"
  value       = aws_instance.boundary_pki_worker.public_ip
}

output "hcp-b-url" {
  description = "HCP Boundary public URL:"
  value       = hcp_boundary_cluster.offsite-2024.cluster_url
}

output "hcp-b-u" {
  description = "HCP Boundary admin username:"
  value       = hcp_boundary_cluster.offsite-2024.username
  sensitive   = true
}
output "hcp-b-p" {
  description = "HCP Boundary admin password:"
  value       = hcp_boundary_cluster.offsite-2024.password
  sensitive   = true
}

output "secret_private_ec2_ip" {
  description = "The Private IPv4 address of the EC2 target provision by the Operator:"
  value       = aws_instance.main.private_ip
}

output "public-ec2_key" {
  description = "PEM:"
  value       = tls_private_key.public-ec2_rsa_4096_key.private_key_pem
  sensitive   = true
}
