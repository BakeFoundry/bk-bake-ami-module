# =============================================================================
# Terraform Tests: ami_builder module
# =============================================================================
# Tests the ami_builder submodule in isolation using `plan` command only,
# since actual Packer builds require AWS credentials and running instances.
#
# These tests verify:
#   - The module initializes correctly with valid inputs
#   - Variable validation and defaults work as expected
#   - The null_resource is properly configured with correct triggers
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Module initializes with all required variables
# -----------------------------------------------------------------------------
# Verifies the ami_builder module can be planned successfully when all
# required variables are provided. Uses plan-only mode since the actual
# Packer build cannot run without AWS credentials.
# -----------------------------------------------------------------------------
run "builder_initializes_with_valid_inputs" {
  command = plan

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
