variable "ami_name" {
  description = "The name pattern for the AMI (e.g., al2023-ami-2023*-kernel-6.1-x86_64)"
  type        = string
}

variable "ami_owner" {
  description = "The owner ID or alias for the AMI (e.g., amazon)"
  type        = string
  default     = "amazon"
}

variable "ami_architecture" {
  description = "The architecture of the AMI (e.g., x86_64 or arm64)"
  type        = string
  default     = "x86_64"
}

variable "ami_os_type" {
  description = "The operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["linux", "windows"], lower(var.ami_os_type))
    error_message = "The ami_os_type must be either Linux or Windows (case-insensitive)."
  }
}

variable "aws_region" {
  description = "The AWS region to use for fetching the AMI"
  type        = string
  default     = "us-east-1"
}

variable "baking_recipe_playbook" {
  description = "The baking recipe playbook to use for baking the AMI"
  type        = string
}

variable "application_name" {
  description = "The name of the application to bake"
  type        = string
}

variable "version_tag" {
  description = "The version tag to append to the baked AMI name"
  type        = string
  default     = ""
}
