output "VAULT_ADDR" {
  description = "HCP Vault public URL: to be used as variable in TFC Workspace:"
  value       = hcp_vault_cluster.offsite-2024.vault_public_endpoint_url
}

output "vault_token" {
  description = "Vault Token"
  value       = hcp_vault_cluster_admin_token.hcp-v-offsite-2024.token
  sensitive   = true
}
