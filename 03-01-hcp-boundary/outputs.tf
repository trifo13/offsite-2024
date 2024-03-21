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

#
###
#

output "secret_private_ec2_ip" {
  description = "The Private IPv4 address of the EC2 target provision by the Operator:"
  value       = aws_instance.main.private_ip
}

output "aws_creds_op_key" {
  description = "Operator key verification"
  value       = data.vault_aws_access_credentials.creds.access_key
  sensitive   = true
}
