terraform {
  cloud {
    organization = "Change-to-your-own-TFC-Org"

    workspaces {
      name = "Change-to-your-own-TFC-Org-Workspace"
    }
  }
}

provider "hcp" {}

provider "vault" {
  token = hcp_vault_cluster_admin_token.hcp-v-offsite-2024.token
}

provider "aws" {
  region     = var.region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
}