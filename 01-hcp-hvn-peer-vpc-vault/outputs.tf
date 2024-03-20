output "VAULT_ADDR" {
  description = "HCP Vault public URL to be used as variable in TFC Workspace:"
  value       = hcp_vault_cluster.offsite-2024.vault_public_endpoint_url
}
