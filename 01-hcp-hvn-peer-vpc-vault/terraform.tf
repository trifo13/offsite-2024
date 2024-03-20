terraform {
  cloud {
    organization = "Change-to-your-own-TFC-Org"

    workspaces {
      name = "Change-to-your-own-TFC-Org-Workspace"
    }
  }
}
provider "hcp" {}

provider "aws" {
  region = var.region
}
