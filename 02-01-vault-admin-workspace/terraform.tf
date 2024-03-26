terraform {
  cloud {
    organization = "IMPORTANT: Change-to-your-own-TFC-Org"

    workspaces {
      name = "GSS-Offsite-India-2024"
    }
  }
}

# Dynamically generate token a for HCP Vault using the variables we set in TFC:
provider "vault" {
  token = hcp_vault_cluster_admin_token.hcp-v-offsite-2024.token
}

provider "hcp" {}

provider "aws" {
  region = var.region
}
