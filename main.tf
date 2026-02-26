module "ami_fetcher" {
  source = "./modules/ami_fetcher"

  ami_name         = var.ami_name
  ami_owner        = var.ami_owner
  ami_architecture = var.ami_architecture
  ami_os_type      = var.ami_os_type
}
