# AWS Vars


# Subnet Vars
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet" {
  default = "10.0.0.0/24"
}

# Main Vars
variable "zone" {
  default = ["eu-west-1a","eu-west-1b"]
}

variable "my_key_name" {
  default = "ssh-key"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "environment" {
  default = "development"
}

variable "instance_public_ip" {
  default = ""
  }
