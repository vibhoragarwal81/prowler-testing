
variable "region" { default = "us-east-1" }
variable "results_bucket_name" {}
variable "github_repo" {} # e.g., vibhor/prowler-org-scanner
variable "management_account_id" {}

provider "aws" {
  region = var.region
}

# Fetch all accounts in the organization
data "aws_organizations_organization" "org" {}

data "aws_organizations_accounts" "accounts" {}

# Create S3 bucket for Prowler results
resource "aws_s3_bucket" "prowler_results" {
  bucket = var.results_bucket_name
  force_destroy = true

  tags = {
    Name    = "ProwlerResults"
    Purpose = "Centralized Prowler Scan Storage"
  }
}

# GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98c6a5d7b5a0e3b1a1f2b5e3e1b3c2f3"]
}

# GitHubProwlerRunner role in management account
resource "aws_iam_role" "github_prowler_runner" {
  name = "GitHubProwlerRunner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_prowler_runner_policy" {
  role = aws_iam_role.github_prowler_runner.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRole",
          "organizations:ListAccounts",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = [aws_s3_bucket.prowler_results.arn, "${aws_s3_bucket.prowler_results.arn}/*"]
      }
    ]
  })
}

# Configure provider aliases for each member account
provider "aws" {
  alias  = "member"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.management_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Create ProwlerAuditRole in each member account dynamically
resource "aws_iam_role" "prowler_audit_role" {
  for_each = { for acc in data.aws_organizations_accounts.accounts.accounts : acc.id => acc }

  provider = aws.member

  name = "ProwlerAuditRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:role/GitHubProwlerRunner"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "prowler_audit_policy" {
  for_each = aws_iam_role.prowler_audit_role

  provider = aws.member

  role = each.value.name

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
