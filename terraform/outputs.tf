output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "Web security group id"
  value       = aws_security_group.web.id
}

output "bucket_name" {
  description = "Artifacts S3 bucket name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "app_role_arn" {
  description = "IAM role ARN for the app"
  value       = aws_iam_role.app.arn
}
