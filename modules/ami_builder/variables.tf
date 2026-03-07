variable "source_ami_id" {
  description = "The ID of the source AMI to bake"
  type        = string
}

variable "source_ami_arn" {
  description = "The ARN of the source AMI to bake"
  type        = string
}

variable "baking_recipe_playbook" {
  description = "The baking recipe playbook to use for baking the AMI"
  type        = string
}

variable "application_name" {
  description = "The name of the application to bake"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to use for building the AMI"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type to use for the Packer build"
  type        = string
  default     = "t3.micro"
}

variable "ssh_username" {
  description = "The SSH username for connecting to the build instance"
  type        = string
  default     = "ec2-user"
}
