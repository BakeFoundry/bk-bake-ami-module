# =============================================================================
# Terraform Tests: ami_builder module
# =============================================================================
# Tests the ami_builder submodule using `apply` to verify the full Packer
# build runs and produces a valid AMI.
#
# These tests verify:
#   - The module initializes and applies successfully
#   - Packer builds a new AMI from the source AMI
#   - The baked AMI ID is valid and starts with "ami-"
#
# Prerequisites: AWS credentials and Packer must be available
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Full AMI build produces a valid baked AMI
# -----------------------------------------------------------------------------
# Applies the ami_builder module to actually run Packer and create a new AMI.
# Verifies the triggers are correct and the resulting AMI ID is valid.
# -----------------------------------------------------------------------------
run "builder_creates_ami" {
  command = apply

  module {
    source = "./modules/ami_builder"
  }

  variables {
    source_ami_id          = "ami-02dfbd4ff395f2a1b"
    source_ami_arn         = "arn:aws:ec2:us-east-1::image/ami-02dfbd4ff395f2a1b"
    baking_recipe_playbook = "./tests/playbooks/test_bake.yml"
    application_name       = "test-app"
    aws_region             = "us-east-1"
    instance_type          = "t3.micro"
    ssh_username           = "ec2-user"
  }

  # Verify the null_resource trigger has the correct source AMI ID
  assert {
    condition     = null_resource.packer_build.triggers.source_ami_id == "ami-02dfbd4ff395f2a1b"
    error_message = "Packer build trigger should contain the correct source AMI ID"
  }

  # Verify the newly baked AMI ID follows the expected format
  assert {
    condition     = startswith(output.baked_ami_id, "ami-")
    error_message = "Baked AMI ID should start with 'ami-' prefix, got: ${output.baked_ami_id}"
  }
}
