provider "aws" {
  region = var.region
}

variable "org_management_account_id" {}
variable "results_bucket_name" {}
variable "region" { default = "us-east-1" }

resource "aws_s3_bucket" "prowler_results" {
  bucket = var.results_bucket_name
  force_destroy = true

  tags = {
    Name = "ProwlerResults"
    Purpose = "Centralized Prowler Scan Storage"
  }
}

resource "aws_s3_bucket_policy" "allow_org_access" {
  bucket = aws_s3_bucket.prowler_results.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowOrgAccountsToPutObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.prowler_results.arn}/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.org_management_account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "prowler_audit_role" {
  name = "ProwlerAuditRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.org_management_account_id}:root"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "prowler_permissions" {
  role = aws_iam_role.prowler_audit_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "securityhub:BatchImportFindings",
          "securityhub:Get*",
          "securityhub:Describe*",
          "securityhub:List*",
          "ec2:Describe*",
          "iam:GenerateCredentialReport",
          "iam:Get*",
          "iam:List*",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:LookupEvents",
          "config:Describe*",
          "config:Get*",
          "config:List*"
        ],
        Resource = "*"
      }
    ]
  })
}
