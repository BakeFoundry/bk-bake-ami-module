output "ami_id" {
  description = "The ID of the selected AMI"
  value       = data.aws_ami.selected.id
}

output "ami_name" {
  description = "The name of the selected AMI"
  value       = data.aws_ami.selected.name
}

output "ami_arn" {
  description = "The ARN of the selected AMI"
  value       = data.aws_ami.selected.arn
}
