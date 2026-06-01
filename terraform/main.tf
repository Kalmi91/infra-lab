# Week 1–2 starter. This is intentionally small: one VPC + subnet, one S3
# bucket, one IAM role. It proves the LocalStack loop works end to end. Extend
# it as you learn (add an internet gateway, route tables, security groups, more
# subnets across AZs, etc.) — that learning IS the portfolio.

# --- Network -----------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name    = "infra-lab"
    Project = "infra-lab"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "infra-lab-public-a"
  }
}

# --- Storage -----------------------------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket = "infra-lab-artifacts"
  tags = {
    Project = "infra-lab"
  }
}

# --- IAM ---------------------------------------------------------------------
resource "aws_iam_role" "app" {
  name = "infra-lab-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Project = "infra-lab"
  }
}

# --- Outputs -----------------------------------------------------------------
output "vpc_id" {
  value = aws_vpc.main.id
}

output "bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}
