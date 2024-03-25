terraform {
  cloud {
    organization = "IMPORTANT: Change-to-your-own-TFC-Org"

    workspaces {
      name = "GSS-Offsite-India-2024"
    }
  }
}

provider "hcp" {}

provider "aws" {
  region = var.region
}
