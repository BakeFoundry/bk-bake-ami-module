resource "null_resource" "packer_build" {
  triggers = {
    source_ami_id          = var.source_ami_id
    baking_recipe_playbook = var.baking_recipe_playbook
    application_name       = var.application_name
    version_tag            = var.version_tag
  }

  provisioner "local-exec" {
    command     = <<-EOT
      packer init . && \
      packer build \
        -var "source_ami_id=${var.source_ami_id}" \
        -var "application_name=${var.application_name}" \
        -var "aws_region=${var.aws_region}" \
        -var "instance_type=${var.instance_type}" \
        -var "ssh_username=${var.ssh_username}" \
        -var "baking_recipe_playbook=${abspath(var.baking_recipe_playbook)}" \
        -var "version_tag=${var.version_tag}" \
        .
    EOT
    working_dir = "${path.module}/packer"
  }
}

data "local_file" "packer_manifest" {
  depends_on = [null_resource.packer_build]
  filename   = "${path.module}/packer/packer-manifest.json"
}

locals {
  manifest     = jsondecode(data.local_file.packer_manifest.content)
  baked_ami    = local.manifest.builds[length(local.manifest.builds) - 1]
  baked_ami_id = element(split(":", local.baked_ami.artifact_id), 1)
}

# Deregister the baked AMI on destroy (e.g., during terraform test teardown)
resource "null_resource" "ami_cleanup" {
  triggers = {
    baked_ami_id = local.baked_ami_id
    aws_region   = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 deregister-image --image-id ${self.triggers.baked_ami_id} --region ${self.triggers.aws_region}"
  }
}
