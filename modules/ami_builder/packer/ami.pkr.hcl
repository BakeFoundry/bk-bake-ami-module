# =============================================================================
# Packer Template: AMI Builder
# =============================================================================
# This template creates a new Amazon Machine Image (AMI) by:
#   1. Launching a temporary EC2 instance from a source AMI
#   2. Running an Ansible playbook to install/configure the application
#   3. Snapshotting the instance into a new AMI
#   4. Writing a manifest file with the new AMI ID for Terraform to consume
#
# Usage (invoked automatically by Terraform via null_resource):
#   packer init .
#   packer build -var "source_ami_id=ami-xxx" -var "application_name=my-app" ...
# =============================================================================

# -----------------------------------------------------------------------------
# Required Plugins
# -----------------------------------------------------------------------------
# - amazon: Provides the "amazon-ebs" builder to create EBS-backed AMIs
# - ansible: Provides the "ansible" provisioner to run Ansible playbooks on
#            the temporary EC2 instance during the build process
# -----------------------------------------------------------------------------
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# -----------------------------------------------------------------------------
# Input Variables
# -----------------------------------------------------------------------------
# These are passed in from Terraform via the `-var` flags in the local-exec
# provisioner (see ami_builder/main.tf). They are separate from Terraform
# variables — Packer has its own variable system.
# -----------------------------------------------------------------------------

# The base AMI to start from (output of ami_fetcher module)
# Example: "ami-0abcdef1234567890"
variable "source_ami_id" {
  type        = string
  description = "The ID of the source AMI to bake"
}

# Used to generate the AMI name and passed to the Ansible playbook
# Example: "my-web-app"
variable "application_name" {
  type        = string
  description = "The name of the application to bake"
}

# AWS region where the build instance will be launched and the AMI will be created
# Example: "us-east-1"
variable "aws_region" {
  type        = string
  description = "The AWS region to use for building the AMI"
  default     = "us-east-1"
}

# EC2 instance type for the temporary build instance
# Choose based on your playbook's resource needs (CPU, memory)
# Example: "t3.micro", "t3.medium", "m5.large"
variable "instance_type" {
  type        = string
  description = "The EC2 instance type to use for the Packer build"
  default     = "t3.micro"
}

# SSH username depends on the source AMI's OS:
#   - Amazon Linux / RHEL:  "ec2-user"
#   - Ubuntu:               "ubuntu"
#   - Debian:               "admin"
#   - CentOS:               "centos"
variable "ssh_username" {
  type        = string
  description = "The SSH username for connecting to the build instance"
  default     = "ec2-user"
}

# Absolute or relative path to the Ansible playbook that configures the AMI
# Example: "./playbooks/install_nginx.yml"
variable "baking_recipe_playbook" {
  type        = string
  description = "Path to the Ansible playbook for baking the AMI"
}

# The version tag to append to the baked AMI name
# Example: "v1.2.3"
variable "version_tag" {
  type        = string
  description = "The version tag to append to the baked AMI name"
  default     = ""
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
# Generates a unique AMI name by combining the application name with a
# timestamp. This ensures every build produces a distinctly named AMI.
#
# Example output: "my-web-app-20260307121000"
# Format:          {app_name}-{YYYY}{MM}{DD}{HH}{mm}{ss}
# -----------------------------------------------------------------------------
locals {
  ami_name_suffix = var.version_tag != "" ? "-${var.version_tag}" : ""
  ami_name        = "${var.application_name}-${formatdate("YYYYMMDDHHmmss", timestamp())}${local.ami_name_suffix}"
}

# -----------------------------------------------------------------------------
# Source: amazon-ebs
# -----------------------------------------------------------------------------
# Defines the builder configuration. Packer will:
#   1. Launch a temporary EC2 instance using `source_ami` in `region`
#   2. Wait for SSH connectivity on the `ssh_username`
#   3. Hand off to the build block's provisioners
#   4. Stop the instance and create an AMI snapshot from its EBS volume
#   5. Tag the resulting AMI with metadata for identification
# -----------------------------------------------------------------------------
source "amazon-ebs" "baked_ami" {
  ami_name      = local.ami_name        # Unique name: "my-web-app-20260307121000"
  instance_type = var.instance_type     # Temporary instance size for the build
  region        = var.aws_region        # Region for both the instance and the AMI
  source_ami    = var.source_ami_id     # Base AMI from ami_fetcher
  ssh_username  = var.ssh_username      # OS-specific SSH user

  # Tags applied to the resulting AMI for traceability
  tags = {
    Name        = local.ami_name
    Application = var.application_name
    BuiltBy     = "packer"
    SourceAMI   = var.source_ami_id
  }
}

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------
# Orchestrates the provisioning and post-processing steps:
#
#   1. PROVISIONER (ansible):
#      - Runs the baking recipe playbook on the temporary EC2 instance
#      - Passes `application_name` as an Ansible extra variable so the
#        playbook can use it (e.g., for directory names, service names)
#
#   2. POST-PROCESSOR (manifest):
#      - After AMI creation, writes `packer-manifest.json` containing the
#        new AMI's artifact ID (e.g., "us-east-1:ami-0newbaked987654321")
#      - This file is read by Terraform (data "local_file") to extract
#        the baked AMI ID as a Terraform output
# -----------------------------------------------------------------------------
build {
  sources = ["source.amazon-ebs.baked_ami"]

  # Run the Ansible playbook to install and configure the application
  provisioner "ansible" {
    playbook_file = var.baking_recipe_playbook
    extra_arguments = [
      "--extra-vars",
      "application_name=${var.application_name}"
    ]
  }

  # Write a manifest JSON file so Terraform can read back the new AMI ID
  # Example output in packer-manifest.json:
  # {
  #   "builds": [{
  #     "artifact_id": "us-east-1:ami-0newbaked987654321",
  #     "builder_type": "amazon-ebs",
  #     ...
  #   }]
  # }
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
