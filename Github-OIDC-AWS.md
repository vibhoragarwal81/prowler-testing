# GitHub OIDC → AWS STS (Prowler Org Scan)
 
This document explains the solution where **GitHub Actions OIDC token** is exchanged directly with **AWS STS** to assume a role and run the Prowler org scan.
 
It covers:
 
1. What changes in this solution  
2. What needs to be set up outside the YAML  
3. Full workflow of the solution  
4. What AWS sees in this solution  
 
---
 
## 1. What changes in the GitHub OIDC solution
 
### 1.1 Changes inside the GitHub workflow YAML
 
#### Enable OIDC token in the workflow
 
```yaml
permissions:
  id-token: write
  contents: read
```

### Use AWS OIDC credentials action
---
- name: Configure AWS credentials via OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.MANAGEMENT_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
    role-session-name: prowlersession
No AWS access keys required
No AWS_ACCESS_KEY_ID
No AWS_SECRET_ACCESS_KEY
Everything is short-lived, retrieved from STS
Everything else (Prowler install, loops, scanning) stays same
2. What needs to be set up outside the YAML
2.1 In AWS
Create an OIDC Identity Provider
URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
Create IAM Role for GitHub to assume
Example trust policy:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<MGMT_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:ref:refs/heads/main"
        }
      }
    }
  ]
}
Permissions to attach
organizations:ListAccounts
sts:AssumeRole (into member accounts)
Prowler-required service permissions
Member account role (optional)
e.g. OrganizationAccountAccessRole or a custom Prowler role
2.2 In GitHub
Store:
MANAGEMENT_ROLE_ARN
Workflow repo + branch must match the IAM trust policy.
3. Full workflow (end-to-end)
GitHub job starts with id-token: write
GitHub OIDC issues token describing:
repo
branch
workflow identity
aws-actions/configure-aws-credentials calls STS:
aws sts assume-role-with-web-identity
AWS validates:
issuer = GitHub OIDC
audience = sts.amazonaws.com
sub = allowed repo + branch
STS returns:
AccessKeyId
SecretAccessKey
SessionToken
GitHub workflow exports them
Prowler runs using these STS credentials
Credentials expire automatically
4. What AWS sees
FieldValueIdentity ProviderGitHub OIDCIssuerhttps://token.actions.githubusercontent.comKey Claimsub = repo:<org>/<repo>:ref:refs/heads/mainAWS Identityarn:aws:sts::<acct>:assumed-role/<GitHubRole>/prowlersession
AWS never sees Microsoft Entra in this solution.
 
---
 
