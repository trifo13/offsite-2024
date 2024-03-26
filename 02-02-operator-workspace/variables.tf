variable "project_name" {
  type        = string
  description = "Name of the example project."

  default = "dynamic-aws-creds-operator"
}

variable "ttl" {
  type        = string
  description = "Value for TTL tag."

  default = "1"
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

variable "hcp-vault_tier" {
  description = "HCP Vault cluster tier."
  type        = string
  default     = "dev"
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

variable "subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20", "172.31.64.0/20"]
}
