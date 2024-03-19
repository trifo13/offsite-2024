terraform {
  cloud {
    organization = "Change-to-your-own-TFC-Org"

    workspaces {
      name = "Change-to-your-own-TFC-Org-Workspace"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "vault" {}
