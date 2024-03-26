output "BOUNDARY_ADDR" {
  description = "HCP Boundary public URL: to be used as variable in TFC Workspace:"
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
