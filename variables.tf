#AWS region with which we operate
variable "aws_region" {
  default = "us-east-1"
}

#Base CIDR block for our VPC
variable "base_cidr_block" {
  description = "A /16 CIDR range, that the VPC will use"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "A list of availability zones to which we assign subnets"
  type 	      = list (string)
  default     = ["us-east-1a","us-east-1b"]
}

variable "subnet_ids" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "bastion_subnet_ids" {

  default = ["10.0.254.0/24", "10.0.255.0/24"]
}
