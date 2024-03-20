terraform {
  cloud {
    organization = "Change-to-your-own-TFC-Org"

    workspaces {
      name = "Change-to-your-own-TFC-Org-Workspace"
    }
  }
}

provider "hcp" {}

# Dynamically generate token a for HCP Vault using the variables we set in TFC:
provider "vault" {
  token = hcp_vault_cluster_admin_token.hcp-v-offsite-2024.token
}

provider "aws" {
  region = var.region
}
