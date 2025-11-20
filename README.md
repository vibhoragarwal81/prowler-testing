# Difference Between Microsoft Entra OIDC and GitHub OIDC
 
## 1. Who is actually issuing the token?
 
### GitHub OIDC
- **Issuer:** `https://token.actions.githubusercontent.com`
- **What it represents:**  
  A **workload identity** – “this specific GitHub Actions job, in this repo, on this branch/environment”.
- **Token is short-lived**, created automatically by GitHub during the workflow run.
- **Use case:** CI/CD jobs running on GitHub runners.
 
### Microsoft Entra OIDC
- **Issuer:** our tenant, e.g.  
  `https://login.microsoftonline.com/<tenant-id>/v2.0`
- **What it represents:**  
  A **user or service principal** in Entra ID (formerly Azure AD).
- **Token is meant for Microsoft Entra applications**, not GitHub workflows.
- **Use case:** interactive users, daemon apps, Azure workloads, and enterprise applications.
 
---
 
## 2. How they integrate with AWS STS
 
### GitHub OIDC → AWS STS (Recommended)
We normally:
1. Create an **AWS OIDC provider** with URL `https://token.actions.githubusercontent.com`.
2. Create an **IAM role** that trusts GitHub OIDC and restricts by repo/branch.
3. In GitHub workflow, enable `id-token: write` and GitHub automatically exchanges OIDC → STS.
 
This is the **clean, native path** for AWS deployments from GitHub.
 
### Microsoft Entra OIDC → AWS STS
This is possible but not as simpler for GitHub CI:
- Requires GitHub → Entra authentication steps first.
- Then a custom broker/federation to AWS.
- More complex and unnecessary for GitHub pipelines.
 
---
 
## 3. Practical differences for AWS Pipelines
 
| Aspect | GitHub OIDC | Microsoft Entra OIDC |
|--------|-------------|----------------------|
| IdP | GitHub Actions | Entra tenant |
| Identity type | Workflow/job identity | User / service principal |
| Best suited for | CI/CD pipelines | Human SSO, enterprise apps |
| AWS integration | Direct & simple | Indirect & complex |
| Recommended for GitHub → AWS | **Yes** | **No** |
 
---
 
## 4. When does Entra matter here?
 
Entra ID matters only when we want:
- Corporate SSO to AWS,
- Humans logging into AWS using Entra,
- Azure workloads authenticating to AWS.
 
## Summary
- Microsoft Entra OIDC represents **users or service principals**, while GitHub OIDC represents **GitHub workflow jobs**.  
- For AWS pipelines, GitHub OIDC could provide **direct, simpler, and intended** method to assume AWS roles.  
- Microsoft Entra OIDC is more suited for **SSO and application auth**, not CI/CD pipelines.  

 
---
 

# GitHub OIDC vs Microsoft Entra OIDC → AWS STS  
### Combined Comparison for Prowler Org-Scan Pipeline
 
This document compares **two methods** of obtaining AWS STS credentials inside a GitHub Actions workflow:
 
1. **GitHub OIDC → AWS STS**  
2. **Microsoft Entra OIDC → AWS STS**
 
It explains:
 
- What changes in each solution  
- What must be configured outside YAML  
- Full authentication flow  
- What AWS sees  
 
---
 
# 1. High-Level Comparison
 
| Feature | GitHub OIDC → AWS | Entra OIDC → AWS |
|--------|--------------------|------------------|
| Identity Provider for AWS | GitHub | Microsoft Entra |
| Requires Azure setup | ❌ No | ✅ Yes |
| Requires GitHub federated credential | ❌ No | ✅ Yes (in Entra) |
| Requires AWS OIDC provider setup | ✅ Yes | ✅ Yes |
| AWS sees GitHub repo/branch | ✅ Yes | ❌ No |
| AWS sees Entra app identity | ❌ No | ✅ Yes |
| Complexity | ⭐ Simple | ⭐⭐⭐ More complex |
| Best for | CI/CD directly from GitHub | Enterprises needing Entra governance |
 
---
 
# 2. GitHub OIDC → AWS STS
 
## 2.1 What changes in the YAML
 
```yaml
permissions:
  id-token: write
  contents: read
 
- name: Configure AWS credentials via OIDC
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.MANAGEMENT_ROLE_ARN }}
    aws-region: us-east-1
    role-session-name: prowlersession
