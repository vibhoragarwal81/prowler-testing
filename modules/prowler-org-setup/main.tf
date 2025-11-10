
variable "region" { default = "us-east-1" }
variable "results_bucket_name" {}
variable "github_repo" {} # e.g., vibhor/prowler-org-scanner

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "prowler_results" {
  bucket = var.results_bucket_name
  force_destroy = true

  tags = {
    Name    = "ProwlerResults"
    Purpose = "Centralized Prowler Scan Storage"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98c6a5d7b5a0e3b1a1f2b5e3e1b3c2f3" # GitHub OIDC thumbprint
  ]
}

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
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy"
        ],
        Resource = "arn:aws:iam::*:role/OrganizationAccountAccessRole"
      },
      
      {
        Effect = "Allow",
        Action = [
        "organizations:ListAccounts"
        ],
        Resource = "*"
      }

      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.prowler_results.arn,
          "${aws_s3_bucket.prowler_results.arn}/*"
        ]
      }
    ]
  })
}
