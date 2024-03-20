variable "hvn_id" {
  description = "HCP HVN ID."
  type        = string
  default     = "hvn-offsite-2024"
}

variable "cluster_id" {
  description = "HCP Vault cluster ID."
  type        = string
  default     = "hcp-v-offsite-2024"
}

variable "peering_id" {
  description = "HCP peering connection ID."
  type        = string
  default     = "peer-offsite-2024"
}

variable "route_id" {
  description = "HCP HVN route ID."
  type        = string
  default     = "route-offsite-2024"
}

variable "region" {
  description = "HCP HVN and resources ID."
  type        = string
  default     = "us-west-2"
}

variable "cloud_provider" {
  description = "HCP HVN and resources Cloud Provider."
  type        = string
  default     = "aws"
}

variable "hcp-vault_tier" {
  description = "HCP Vault cluster tier."
  type        = string
  default     = "dev"
}