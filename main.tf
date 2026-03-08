module "ami_fetcher" {
  source = "./modules/ami_fetcher"

  ami_name         = var.ami_name
  ami_owner        = var.ami_owner
  ami_architecture = var.ami_architecture
  ami_os_type      = var.ami_os_type
}

module "ami_builder" {
  source = "./modules/ami_builder"

  source_ami_id          = module.ami_fetcher.ami_id
  source_ami_arn         = module.ami_fetcher.ami_arn
  baking_recipe_playbook = var.baking_recipe_playbook
  application_name       = var.application_name
  aws_region             = var.aws_region
  version_tag            = var.version_tag

  # Ensure ami_fetcher completes before ami_builder starts
  depends_on = [module.ami_fetcher]
}
