output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID"
}

output "sg_id" {
  value       = aws_security_group.default.id
  description = "Security Group ID"
}

