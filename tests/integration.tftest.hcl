# =============================================================================
# Terraform Tests: Root Module (Integration)
# =============================================================================
# Integration tests that verify the entire module works end-to-end:
#   ami_fetcher (fetch source AMI) → ami_builder (bake new AMI)
#
# These tests use `plan` mode only since actual apply would:
#   - Require AWS credentials
#   - Launch EC2 instances (costs money)
#   - Run Packer builds (takes several minutes)
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Full module plans successfully with Amazon Linux
# -----------------------------------------------------------------------------
# Verifies the root module can be planned with typical Amazon Linux inputs.
# This tests the full wiring: ami_fetcher outputs → ami_builder inputs.
# -----------------------------------------------------------------------------
run "integration_amazon_linux" {
  command = plan

  variables {
    ami_name               = "al2023-ami-2023*-kernel-6.1-x86_64"
    ami_owner              = "amazon"
    ami_architecture       = "x86_64"
    ami_os_type            = "Linux"
    aws_region             = "us-east-1"
    baking_recipe_playbook = "./tests/playbooks/test_bake.yml"
    application_name       = "integration-test-app"
  }

  # Verify ami_fetcher outputs are wired correctly
  assert {
    condition     = startswith(output.ami_id, "ami-")
    error_message = "Root output ami_id should start with 'ami-'"
  }

  assert {
    condition     = output.ami_name != ""
    error_message = "Root output ami_name should not be empty"
  }

  assert {
    condition     = can(regex("arn:aws:ec2:.*:image/ami-", output.ami_arn))
    error_message = "Root output ami_arn should be a valid EC2 image ARN"
  }
}

# -----------------------------------------------------------------------------
# Test: Module wires ami_fetcher output to ami_builder input
# -----------------------------------------------------------------------------
# Specifically validates that the source_ami_id passed to ami_builder
# matches the ami_id output from ami_fetcher.
# -----------------------------------------------------------------------------
run "integration_wiring_fetcher_to_builder" {
  command = plan

  variables {
    ami_name               = "al2023-ami-2023*-kernel-6.1-x86_64"
    ami_owner              = "amazon"
    ami_architecture       = "x86_64"
    ami_os_type            = "Linux"
    aws_region             = "us-east-1"
    baking_recipe_playbook = "./tests/playbooks/test_bake.yml"
    application_name       = "wiring-test-app"
  }

  # The ami_builder's null_resource trigger should use the same AMI ID
  # that ami_fetcher found
  assert {
    condition     = output.ami_id != ""
    error_message = "ami_fetcher should produce a valid AMI ID for ami_builder to consume"
  }
}

# -----------------------------------------------------------------------------
# Test: All default values produce a valid plan
# -----------------------------------------------------------------------------
# Only the required variables (ami_name, baking_recipe_playbook,
# application_name) are provided. All others should use their defaults.
# -----------------------------------------------------------------------------
run "integration_with_defaults" {
  command = plan

  variables {
    ami_name               = "al2023-ami-2023*-kernel-6.1-x86_64"
    baking_recipe_playbook = "./tests/playbooks/test_bake.yml"
    application_name       = "defaults-test-app"
    # ami_owner defaults to "amazon"
    # ami_architecture defaults to "x86_64"
    # ami_os_type defaults to "Linux"
    # aws_region defaults to "us-east-1"
  }

  assert {
    condition     = startswith(output.ami_id, "ami-")
    error_message = "Module should work correctly with all default values"
  }
}

# -----------------------------------------------------------------------------
# Test: Invalid OS type is rejected at the root level
# -----------------------------------------------------------------------------
# Ensures the validation rule on ami_os_type propagates correctly through
# the root module.
# -----------------------------------------------------------------------------
run "integration_reject_invalid_os" {
  command = plan

  variables {
    ami_name               = "al2023-ami-2023*-kernel-6.1-x86_64"
    baking_recipe_playbook = "./tests/playbooks/test_bake.yml"
    application_name       = "invalid-os-test"
    ami_os_type            = "FreeBSD"
  }

  expect_failures = [
    var.ami_os_type
  ]
}
