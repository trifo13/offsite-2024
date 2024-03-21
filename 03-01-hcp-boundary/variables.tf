variable "HCP_B_U" {
  description = "HCP Boundary: The username of the initial admin user. This must be at least 3 characters in length, alphanumeric, hyphen, or period."
  type        = string
  default     = ""
}

variable "HCP_B_P" {
  description = "HCP Boundary: The password of the initial admin user. This must be at least 8 characters in length. Note that this may show up in logs, and it will be stored in the state file."
  type        = string
  default     = ""
}

variable "hcp-b-cluster_id" {
  type        = string
  description = "HCP Boundary cluster ID."
  default     = "offsite-2024"
}

variable "hcp-b_tier" {
  type        = string
  description = "HCP Boundary cluster tier. Standard or Plus"
  default     = "standard"
}

#
###
#

variable "project_name" {
  type        = string
  description = "Name of the example project."
  default     = "dynamic-aws-creds-operator"
}

variable "ttl" {
  type        = string
  description = "Value for TTL tag."
  default     = "1"
}

variable "region" {
  description = "HCP HVN and resources ID."
  type        = string
  default     = "us-west-2"
}

variable "cluster_id" {
  description = "HCP Vault cluster ID."
  type        = string
  default     = "hcp-v-offsite-2024"
}

variable "hvn_id" {
  description = "HCP HVN ID."
  type        = string
  default     = "hvn-offsite-2024"
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
