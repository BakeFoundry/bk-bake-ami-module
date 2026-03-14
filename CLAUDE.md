# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform module for fetching and baking AWS AMIs in the BakeFoundry ecosystem. The root module wires two submodules: `ami_fetcher` (looks up the latest source AMI) and `ami_builder` (bakes a new AMI via Packer + Ansible, reads back the AMI ID from `packer-manifest.json`).

## Common Commands

```bash
# Initialize
terraform init -backend=false

# Validate
terraform validate

# Format check (recursive)
terraform fmt -recursive -check .

# Run all tests (9 cases across 3 files; ami_builder tests create real AWS resources)
terraform test

# Run a single test file
terraform test -filter=tests/ami_fetcher.tftest.hcl
terraform test -filter=tests/integration.tftest.hcl

# Pre-commit (requires Docker running)
pre-commit install
pre-commit run --all-files
```

## Architecture

- **Root module** (`main.tf`): passes variables to `ami_fetcher`, feeds its output `ami_id` into `ami_builder`.
- **`modules/ami_fetcher`**: `aws_ami` data source with filters (name pattern, owner, architecture, OS). Plan-only — no resources created.
- **`modules/ami_builder`**: `null_resource` running `packer init && packer build` via `local-exec`. Packer template lives at `modules/ami_builder/packer/ami.pkr.hcl` (amazon-ebs builder + Ansible provisioner). After build, parses `packer-manifest.json` to extract the baked AMI ID. A destroy-time provisioner deregisters the AMI.

## Key Design Constraints

- **`ami_builder` variables not exposed at root**: `instance_type` (default `t3.micro`) and `ssh_username` (default `ec2-user`) are configurable inside `ami_builder` but the root module does not pass them through. Callers needing to override them must use the submodule directly.
- **`packer-manifest.json` must exist for destroy**: `ami_cleanup`'s destroy-time provisioner reads `local.baked_ami_id` from the manifest via `locals`. If the manifest is absent (e.g., fresh clone), `terraform destroy` will fail. The manifest is written to `modules/ami_builder/packer/packer-manifest.json` and is gitignored.
- **AMI ID extraction**: `artifact_id` in the manifest has the form `region:ami-xxx`. The baked AMI ID is extracted with `element(split(":", artifact_id), 1)`.

## Testing

Tests use `terraform test` (native HCL test framework), located in `tests/`:
- `ami_fetcher.tftest.hcl` — 4 plan-mode tests (lookup, defaults, OS validation)
- `ami_builder.tftest.hcl` — 1 apply-mode test (launches real EC2, needs AWS creds + Packer + Ansible)
- `integration.tftest.hcl` — 4 plan-mode tests (end-to-end module wiring)

Test playbook: `tests/playbooks/test_bake.yml`

## CI/CD

- **CI** (`ci.yml`): pre-commit checks → terraform init/validate/test. Runs on push and PRs to `main`. Uses OIDC for AWS credentials (`BK_ROLE_TO_ASSUME` secret).
- **Release** (`version.yml`): semantic versioning via `bakefoundry/bk-release-workflow@v1`. Dry-run on PRs, real release on merge to `main`. Uses conventional commits.
- **PR notifications** (`notify-pr.yml`): Discord webhook via `BakeFoundry/bk-bake-pr-reviewes` action.

## Pre-commit Hooks

Runs in Docker containers: `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-added-large-files`, `check-merge-conflict`, `terraform fmt`, `checkov` (security scanning).
