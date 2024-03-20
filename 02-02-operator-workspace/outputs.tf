output "aws_creds_op_key" {
  description = "Operator key verification"
  value       = data.vault_aws_access_credentials.creds.access_key
  sensitive   = true
}
