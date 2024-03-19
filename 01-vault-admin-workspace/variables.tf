
variable "project_name" {
  type        = string
  description = "Name of this project."
  default     = "dynamic-aws-creds-vault"
}

variable "region" {
  description = "HCP HVN and resources ID."
  type        = string
  default     = "us-west-2"
}
