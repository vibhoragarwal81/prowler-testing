````mermaid
flowchart LR
 
    subgraph GITHUB["GitHub"]
        WF[Workflow Job Running]
        OIDC[GitHub OIDC Provider]
    end
 
    subgraph AWS["AWS Management Account"]
        AWSOIDC[AWS IAM OIDC Provider for GitHub]
        STS[AWS STS AssumeRoleWithWebIdentity]
        ROLE[AWS IAM Role Trusted by GitHub OIDC]
    end
 
    subgraph ORG["AWS Organization Accounts"]
        MGMT[Management Account Scan]
        MEMBER[Member Accounts Scan via sts AssumeRole]
    end
 
    subgraph PROWLER["Prowler Execution"]
        PScan[Run Prowler Checks]
        Reports[Generate Reports CSV HTML JSON]
    end
 
    %% Flow begins
    WF -->|"Request OIDC token"| OIDC
    OIDC -->|"Return GitHub JWT with repo and branch claims"| WF
 
    WF -->|"Call AssumeRoleWithWebIdentity using GitHub token"| STS
    STS -->|"Validate issuer and audience and subject"| AWSOIDC
    AWSOIDC -->|"Trust matches IAM role conditions"| ROLE
 
    STS -->|"Return temporary AWS credentials"| WF
 
    WF -->|"Use temporary credentials"| PScan
    PScan -->|"List accounts via AWS Organizations"| MGMT
    PScan -->|"Assume role in member accounts"| MEMBER
    PScan --> Reports
````
