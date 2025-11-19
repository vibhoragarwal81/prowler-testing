# GitHub OIDC → AWS STS (Prowler Org Scan)
 
This document explains the solution where **GitHub Actions OIDC token** is exchanged directly with **AWS STS** to assume a role and run the Prowler org scan.
 
It covers:
 
1. Primary components in this solution
2. What needs to be set up inside and outside the YAML  
3. Full workflow of the solution  
4. What AWS sees in this solution  
 
---

## Changes inside the GitHub workflow YAML

### Enable OIDC token in the workflow

_yaml_

_permissions:_

  _id-token: write_

  _contents: read_

**Use AWS OIDC credentials action that are short lived and can be assumed using the github oidc token**

\- name: Configure AWS credentials via OIDC

  uses: aws-actions/configure-aws-credentials@v4

  with:

    role-to-assume: ${{ secrets.MANAGEMENT\_ROLE\_ARN }}

    aws-region: ${{ env.AWS\_REGION }}

    role-session-name: prowlersession

**In this solution, No AWS access keys are required because github oidc token is exchanged with AWS STS token**

*   No AWS\_ACCESS\_KEY\_ID
*   No AWS\_SECRET\_ACCESS\_KEY
*   Everything is short-lived, retrieved from STS

#### Everything else (Prowler installation, loops through the account list, scanning of AWS resources) stays same

### 2\. What needs to be set up outside the YAML ( using the Terraform automation)

**2.1 In AWS**

**Create an OIDC Identity Provider**

*   URL: [https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com "https://token.actions.githubusercontent.com/")
*   Audience: [sts.amazonaws.com](http://sts.amazonaws.com "http://sts.amazonaws.com/")

### Create IAM Role for GitHub to assume

**Management account role ()**

      "Principal":  "Federated": "arn:aws:iam::<MGMT\_ACCOUNT\_ID>:oidc-provider/[token.actions.githubusercontent.com](http://token.actions.githubusercontent.com "http://token.actions.githubusercontent.com/")"

      "Action": "sts:AssumeRoleWithWebIdentity",

      "Condition": "StringEquals": "[token.actions.githubusercontent.com](http://token.actions.githubusercontent.com "http://token.actions.githubusercontent.com/"):aud": "[sts.amazonaws.com](http://sts.amazonaws.com "http://sts.amazonaws.com/")"

        "StringLike": "[token.actions.githubusercontent.com](http://token.actions.githubusercontent.com "http://token.actions.githubusercontent.com/"):sub": "repo:<org>/<repo>:ref:refs/heads/main"

**Permissions to attach**

*   organizations:ListAccounts
*   sts:AssumeRole ( OrganizationAccountAccessRole or a custom Prowler role into member accounts)

**Member account role**

*   IAM policy with Prowler-required service permissions

**2.2 In GitHub**

Store:

*   MANAGEMENT\_ROLE\_ARN

Workflow repo + branch must match the IAM trust policy.

## 3\. Full workflow (end-to-end)

1.       GitHub job starts with id-token: write

2.       GitHub OIDC issues token describing:

repo

branch

workflow identity

3.       aws-actions/configure-aws-credentials calls STS:

4.       aws sts assume-role-with-web-identity

5.       AWS validates:

*   issuer = GitHub OIDC
*   audience = [sts.amazonaws.com](http://sts.amazonaws.com "http://sts.amazonaws.com/")
*   sub = allowed repo + branch

6.       STS returns:

·       AccessKeyId

·       SecretAccessKey

·       SessionToken

7.       GitHub workflow exports them

8.       Prowler runs using these STS credentials

9.       Credentials expire automatically

**4\. What AWS sees**

| Field | Value |
| --- | --- |
| Identity Provider | Github OIDC |
| Issuer | https://token.actions.githubusercontent.com |
| Key Claim | sub = repo:<org>/<repo>:ref:refs/heads/main |
| AWS Identity | arn:aws:sts::<acct>:assumed-role/<GitHubRole>/prowlersession |
 
