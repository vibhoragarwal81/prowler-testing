# \# Difference Between Microsoft Entra OIDC and GitHub OIDC

# &nbsp;

# \## Summary (Pre# Difference Between Microsoft Entra OIDC and GitHub OIDC

# &nbsp;

# \## Summary (Precise)

# \- Microsoft Entra OIDC represents \*\*users or service principals\*\*, while GitHub OIDC represents \*\*GitHub workflow jobs\*\*.  

# \- For AWS pipelines, GitHub OIDC is the \*\*direct, simpler, and intended\*\* method to assume AWS roles.  

# \- Microsoft Entra OIDC is mainly for \*\*SSO and application auth\*\*, not CI/CD pipelines.  

# \- So for AWS STS role assumption in GitHub pipelines, \*\*GitHub OIDC is the correct and recommended choice\*\*.

# &nbsp;

# ---

# &nbsp;

# \## 1. Who is actually issuing the token?

# &nbsp;

# \### GitHub OIDC

# \- \*\*Issuer:\*\* `https://token.actions.githubusercontent.com`

# \- \*\*What it represents:\*\*  

# &nbsp; A \*\*workload identity\*\* – “this specific GitHub Actions job, in this repo, on this branch/environment”.

# \- \*\*Token is short-lived\*\*, created automatically by GitHub during the workflow run.

# \- \*\*Use case:\*\* CI/CD jobs running on GitHub runners.

# &nbsp;

# \### Microsoft Entra OIDC

# \- \*\*Issuer:\*\* our tenant, e.g.  

# &nbsp; `https://login.microsoftonline.com/<tenant-id>/v2.0`

# \- \*\*What it represents:\*\*  

# &nbsp; A \*\*user or service principal\*\* in Entra ID (formerly Azure AD).

# \- \*\*Token is meant for Microsoft Entra applications\*\*, not GitHub workflows.

# \- \*\*Use case:\*\* interactive users, daemon apps, Azure workloads, and enterprise applications.

# &nbsp;

# ---

# &nbsp;

# \## 2. How they integrate with AWS STS

# &nbsp;

# \### GitHub OIDC → AWS STS (Recommended)

# We normally:

# 1\. Create an \*\*AWS OIDC provider\*\* with URL `https://token.actions.githubusercontent.com`.

# 2\. Create an \*\*IAM role\*\* that trusts GitHub OIDC and restricts by repo/branch.

# 3\. In GitHub workflow, enable `id-token: write` and GitHub automatically exchanges OIDC → STS.

# &nbsp;

# This is the \*\*clean, native path\*\* for AWS deployments from GitHub.

# &nbsp;

# \### Microsoft Entra OIDC → AWS STS

# This is possible but not ideal for GitHub CI:

# \- Requires GitHub → Entra authentication steps first.

# \- Then a custom broker/federation to AWS.

# \- More complex and unnecessary for GitHub pipelines.

# &nbsp;

# ---

# &nbsp;

# \## 3. Practical differences for AWS Pipelines

# &nbsp;

# | Aspect | GitHub OIDC | Microsoft Entra OIDC |

# |--------|-------------|----------------------|

# | IdP | GitHub Actions | Entra tenant |

# | Identity type | Workflow/job identity | User / service principal |

# | Best suited for | CI/CD pipelines | Human SSO, enterprise apps |

# | AWS integration | Direct \& simple | Indirect \& complex |

# | Recommended for GitHub → AWS | \*\*Yes\*\* | \*\*No\*\* |

# &nbsp;

# ---

# &nbsp;

# \## 4. When does Entra matter here?

# &nbsp;

# Entra ID matters only when we want:

# \- Corporate SSO to AWS,

# \- Humans logging into AWS using Entra,

# \- Azure workloads authenticating to AWS.

# &nbsp;

# For GitHub pipelines assuming AWS roles, \*\*GitHub OIDC is the right choice\*\*.cise)

# \- Microsoft Entra OIDC represents \*\*users or service principals\*\*, while GitHub OIDC represents \*\*GitHub workflow jobs\*\*.  

# \- For AWS pipelines, GitHub OIDC is the \*\*direct, simpler, and intended\*\* method to assume AWS roles.  

# \- Microsoft Entra OIDC is mainly for \*\*SSO and application auth\*\*, not CI/CD pipelines.  

# \- So for AWS STS role assumption in GitHub pipelines, \*\*GitHub OIDC is the correct and recommended choice\*\*.

# &nbsp;

# ---

# &nbsp;

# \## 1. Who is actually issuing the token?

# &nbsp;

# \### GitHub OIDC

# \- \*\*Issuer:\*\* `https://token.actions.githubusercontent.com`

# \- \*\*What it represents:\*\*  

# &nbsp; A \*\*workload identity\*\* – “this specific GitHub Actions job, in this repo, on this branch/environment”.

# \- \*\*Token is short-lived\*\*, created automatically by GitHub during the workflow run.

# \- \*\*Use case:\*\* CI/CD jobs running on GitHub runners.

# &nbsp;

# \### Microsoft Entra OIDC

# \- \*\*Issuer:\*\* our tenant, e.g.  

# &nbsp; `https://login.microsoftonline.com/<tenant-id>/v2.0`

# \- \*\*What it represents:\*\*  

# &nbsp; A \*\*user or service principal\*\* in Entra ID (formerly Azure AD).

# \- \*\*Token is meant for Microsoft Entra applications\*\*, not GitHub workflows.

# \- \*\*Use case:\*\* interactive users, daemon apps, Azure workloads, and enterprise applications.

# &nbsp;

# ---

# &nbsp;

# \## 2. How they integrate with AWS STS

# &nbsp;

# \### GitHub OIDC → AWS STS (Recommended)

# We normally:

# 1\. Create an \*\*AWS OIDC provider\*\* with URL `https://token.actions.githubusercontent.com`.

# 2\. Create an \*\*IAM role\*\* that trusts GitHub OIDC and restricts by repo/branch.

# 3\. In GitHub workflow, enable `id-token: write` and GitHub automatically exchanges OIDC → STS.

# &nbsp;

# This is the \*\*clean, native path\*\* for AWS deployments from GitHub.

# &nbsp;

# \### Microsoft Entra OIDC → AWS STS

# This is possible but not ideal for GitHub CI:

# \- Requires GitHub → Entra authentication steps first.

# \- Then a custom broker/federation to AWS.

# \- More complex and unnecessary for GitHub pipelines.

# &nbsp;

# ---

# &nbsp;

# \## 3. Practical differences for AWS Pipelines

# &nbsp;

# | Aspect | GitHub OIDC | Microsoft Entra OIDC |

# |--------|-------------|----------------------|

# | IdP | GitHub Actions | Entra tenant |

# | Identity type | Workflow/job identity | User / service principal |

# | Best suited for | CI/CD pipelines | Human SSO, enterprise apps |

# | AWS integration | Direct \& simple | Indirect \& complex |

# | Recommended for GitHub → AWS | \*\*Yes\*\* | \*\*No\*\* |

# &nbsp;

# ---

# &nbsp;

# \## 4. When does Entra matter here?

# &nbsp;

# Entra ID matters only when we want:

# \- Corporate SSO to AWS,

# \- Humans logging into AWS using Entra,

# \- Azure workloads authenticating to AWS.

# &nbsp;

# For GitHub pipelines assuming AWS roles, \*\*GitHub OIDC is the right choice\*\*.

