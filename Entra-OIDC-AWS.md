# AWS Org Scan using Prowler (Microsoft Entra OIDC → AWS STS)

This document explains the solution where GitHub first authenticates to \*\*Microsoft Entra ID using workload identity federation\*\*, obtains an Entra-issued OIDC token, and then uses that Entra token to call \*\*AWS STS\*\*.

AWS sees \*\*Microsoft Entra\*\*, as the identity provider.

A high level overview is divided in below parts

1\. Primary components in this solution  

2\. What needs to be set up in the workflow and github repo secrets

3\. Full workflow details

4\. what AWS see

\---

### Authenticate to Microsoft Entra ( client secret is not needed)

- yamlpermissions:  
id-token: write  
contents: read |


It uses two repository secrets that are App registration client ID and Entra Tenant ID

name: Login to Microsoft Entra (OIDC)  
uses: azure/login@v2  with:
client-id: ${{ secrets.AZURE_CLIENT_ID }}
tenant-id: ${{ secrets.AZURE_TENANT_ID }}
allow-no-subscriptions: true
  

### Obtain Entra token for AWS-configured audience


    TOKEN=$(az account get-access-token \\

      --resource api://aws-sts-entra \\

      --query accessToken -o tsv)

    echo "token=$TOKEN" >> $GITHUB\_OUTPUT

### Exchange Entra token with AWS STS

\- name: Exchange Entra token for AWS STS creds

  run: |

    CREDS=$(aws sts assume-role-with-web-identity \\

      --role-arn "${{ secrets.MANAGEMENT\_ROLE\_ARN }}" \\

      --web-identity-token "${{ steps.entra\_token.outputs.token }}" \\

      --role-session-name prowlersession \\

      --duration-seconds 3600)

    export AWS\_ACCESS\_KEY\_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')

    export AWS\_SECRET\_ACCESS\_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')

    export AWS\_SESSION\_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')

All other Prowler logic remains identical.

### 2\. What needs to be set up outside the YAML

#### 2.1 In Microsoft Entra

**App Registration**

·        Client ID

·        Tenant ID

**Federated credentials (this is must to setup in absence of secret)**

Configure:

*   GitHub org
*   GitHub repo
*   GitHub branch or environment

This allows GitHub’s identity to authenticate **without a client secret**.

**Expose an API → Set Application ID URI**

Example:

api://aws-sts-entra

This becomes the aud claim in the Entra token and must match AWS's OIDC provider audience.

**2.2 In AWS**

**Create OIDC provider for Microsoft Entra using automation(Terraform)**

*   Provider URL: [https://login.microsoftonline.com](https://login.microsoftonline.com "https://login.microsoftonline.com/")/<TENANT\_ID>/v2.0
*   Audience: api://aws-sts-entra

**Create IAM Role trusted by Entra**

**Attach permissions for Prowler scanning**

Same as GitHub OIDC role.

### 3\. Full workflow (end-to-end)

1.       GitHub job starts (id-token: write enabled)

2.       azure/login uses GitHub OIDC token to authenticate to Entra

3.       Entra evaluates federated credential → approves login

4.       Workflow obtains Entra access token via:

5.       az account get-access-token --resource api://aws-sts-entra

6.       Workflow calls:

7.       aws sts assume-role-with-web-identity using the **Entra token**, not GitHub token

8.       AWS validates:

·       issuer = Microsoft Entra

·       aud = api://aws-sts-entra

·       appid = Entra app registration ID

9.       STS issues temporary AWS credentials

10.  Prowler runs normally using these short-lived credentials

11.  Tokens expire automatically

## Architecture Diagram
<img width="1433" height="946" alt="image" src="https://github.com/user-attachments/assets/70be4ead-a459-493b-9fbe-b87ef90411f9" />

### 4\. What AWS sees in the Entra OIDC solution
````
Field                                                              Value
Identity Provider                                                  Entra OIDC
Issuer                                                             https://login.microsoftonline.com/<TENANT_ID>/v2.0
Claimappid                                                         <AZURE_CLIENT_ID>
AWS Identity                                                      arn:aws:sts::<acct>:assumed-role/<EntraRole>/prowlersession
GitHub visibility                                                   Not visible to AWS at allAWS sees Microsoft Entra app registration as the caller — not GitHub. |
````


