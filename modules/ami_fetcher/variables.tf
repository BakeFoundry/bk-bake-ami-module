variable "ami_name_filter" {
  description = "The name pattern for the AMI (e.g., al2023-ami-2023*-kernel-6.1-x86_64)"
  type        = string
}

variable "ami_owner" {
  description = "The owner ID or alias for the AMI (e.g., amazon)"
  type        = string
  default     = "amazon"
}

variable "architecture" {
  description = "The architecture of the AMI (e.g., x86_64 or arm64)"
  type        = string
  default     = "x86_64"
}

variable "os_type" {
  description = "The operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "The os_type must be either Linux or Windows."
  }
}
