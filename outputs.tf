output "ami_id" {
  description = "The ID of the selected AMI"
  value       = module.ami_fetcher.ami_id
}

output "ami_name" {
  description = "The name of the selected AMI"
  value       = module.ami_fetcher.ami_name
}

output "ami_arn" {
  description = "The ARN of the selected AMI"
  value       = module.ami_fetcher.ami_arn
}
