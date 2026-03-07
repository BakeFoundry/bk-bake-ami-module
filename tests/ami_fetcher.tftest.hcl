# =============================================================================
# Terraform Tests: ami_fetcher module
# =============================================================================
# Tests the ami_fetcher submodule in isolation to verify it can correctly
# look up an AMI by name pattern, owner, architecture, and OS type.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Fetch a valid Amazon Linux 2023 AMI with default settings
# -----------------------------------------------------------------------------
# Verifies that the module successfully returns an AMI ID, ARN, and name
# when searching for a valid Amazon Linux 2023 AMI pattern.
# -----------------------------------------------------------------------------
run "fetch_amazon_linux_ami" {
  command = plan

  module {
    source = "./modules/ami_fetcher"
  }

  variables {
    ami_name         = "al2023-ami-2023*-kernel-6.1-x86_64"
    ami_owner        = "amazon"
    ami_architecture = "x86_64"
    ami_os_type      = "Linux"
  }

  # Verify outputs are not empty
  assert {
    condition     = output.ami_id != ""
    error_message = "ami_id output should not be empty"
  }

  assert {
    condition     = output.ami_arn != ""
    error_message = "ami_arn output should not be empty"
  }

  assert {
    condition     = output.ami_name != ""
    error_message = "ami_name output should not be empty"
  }

  # Verify AMI ID format: must start with "ami-"
  assert {
    condition     = startswith(output.ami_id, "ami-")
    error_message = "ami_id should start with 'ami-' prefix, got: ${output.ami_id}"
  }

  # Verify ARN format: must contain ":image/"
  assert {
    condition     = can(regex("arn:aws:ec2:.*:image/ami-", output.ami_arn))
    error_message = "ami_arn should be a valid EC2 image ARN, got: ${output.ami_arn}"
  }
}

# -----------------------------------------------------------------------------
# Test: Verify default variable values are applied correctly
# -----------------------------------------------------------------------------
# Ensures the module uses sensible defaults (amazon owner, x86_64, Linux)
# when only the required ami_name variable is provided.
# -----------------------------------------------------------------------------
run "fetch_ami_with_defaults" {
  command = plan

  module {
    source = "./modules/ami_fetcher"
  }

  variables {
    ami_name = "al2023-ami-2023*-kernel-6.1-x86_64"
    # ami_owner defaults to "amazon"
    # ami_architecture defaults to "x86_64"
    # ami_os_type defaults to "Linux"
  }

  assert {
    condition     = startswith(output.ami_id, "ami-")
    error_message = "Should find an AMI with default variable values"
  }
}

# -----------------------------------------------------------------------------
# Test: Validate ami_os_type rejects invalid values
# -----------------------------------------------------------------------------
# The ami_os_type variable has a validation rule that only allows "Linux"
# or "Windows" (case-insensitive). This test ensures invalid values are
# properly rejected.
# -----------------------------------------------------------------------------
run "reject_invalid_os_type" {
  command = plan

  module {
    source = "./modules/ami_fetcher"
  }

  variables {
    ami_name    = "al2023-ami-2023*-kernel-6.1-x86_64"
    ami_os_type = "InvalidOS"
  }

  expect_failures = [
    var.ami_os_type
  ]
}

# -----------------------------------------------------------------------------
# Test: Verify case-insensitive OS type validation
# -----------------------------------------------------------------------------
# The validation should accept "linux", "LINUX", "Linux", etc.
# -----------------------------------------------------------------------------
run "accept_lowercase_os_type" {
  command = plan

  module {
    source = "./modules/ami_fetcher"
  }

  variables {
    ami_name    = "al2023-ami-2023*-kernel-6.1-x86_64"
    ami_os_type = "linux"
  }

  assert {
    condition     = startswith(output.ami_id, "ami-")
    error_message = "Should accept lowercase 'linux' as a valid OS type"
  }
}
