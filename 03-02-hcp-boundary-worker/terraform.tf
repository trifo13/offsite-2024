terraform {
  cloud {
    organization = "IMPORTANT: Change-to-your-own-TFC-Org"

    workspaces {
      name = "GSS-Offsite-India-2024"
    }
  }
}

provider "hcp" {}

provider "vault" {
  token = hcp_vault_cluster_admin_token.hcp-v-offsite-2024.token
}

provider "aws" {
  region = var.region
}

provider "boundary" {
  addr                   = var.BOUNDARY_ADDR
  auth_method_login_name = var.HCP_B_U
  auth_method_password   = var.HCP_B_P
}
