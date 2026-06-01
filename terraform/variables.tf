variable "region" {
  description = "AWS region. LocalStack ignores it, but the provider requires one."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used as a tag and a resource-name prefix."
  type        = string
  default     = "infra-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  description = "Availability zones for the public subnets (must match the CIDR list length)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}
