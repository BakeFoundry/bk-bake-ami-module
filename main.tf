module "ami_fetcher" {
  source = "./modules/ami_fetcher"

  ami_name_filter = var.ami_name
  ami_owner       = var.ami_owner
  architecture    = var.ami_architecture
  os_type         = var.ami_os_type
}
