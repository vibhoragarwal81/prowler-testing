import boto3
import json
import os

def assume_role(role_arn, session_name):
    sts_client = boto3.client('sts')
    response = sts_client.assume_role(RoleArn=role_arn, RoleSessionName=session_name)
    return response['Credentials']

def create_prowler_role(account_id, management_role_arn):
    org_access_role_arn = f"arn:aws:iam::{account_id}:role/OrganizationAccountAccessRole"
    creds = assume_role(org_access_role_arn, "OrgAccessSession")

    iam_client = boto3.client(
        'iam',
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken']
    )

    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": management_role_arn},
                "Action": "sts:AssumeRole"
            }
        ]
    }

    try:
        iam_client.create_role(
            RoleName="ProwlerAuditRole",
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Role for Prowler scanning in member account"
        )
        print(f"Created ProwlerAuditRole in account {account_id}")
    except iam_client.exceptions.EntityAlreadyExistsException:
        print(f"ProwlerAuditRole already exists in account {account_id}")

    policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "securityhub:BatchImportFindings",
                    "securityhub:Get*",
                    "securityhub:Describe*",
                    "securityhub:List*",
                    "ec2:Describe*",
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
                "Resource": "*"
            }
        ]
    }

    iam_client.put_role_policy(
        RoleName="ProwlerAuditRole",
        PolicyName="ProwlerAuditPermissions",
        PolicyDocument=json.dumps(policy_document)
    )
    print(f"Attached policy to ProwlerAuditRole in account {account_id}")

def main():
    management_role_arn = os.getenv("MANAGEMENT_ROLE_ARN")
    if not management_role_arn:
        raise ValueError("MANAGEMENT_ROLE_ARN environment variable is required")

    creds = assume_role(management_role_arn, "ManagementSession")

    org_client = boto3.client(
        'organizations',
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken']
    )

    accounts = []
    paginator = org_client.get_paginator('list_accounts')
    for page in paginator.paginate():
        for acct in page['Accounts']:
            if acct['Status'] == 'ACTIVE':
                accounts.append(acct['Id'])

    print(f"Found accounts: {accounts}")

    for account_id in accounts:
        create_prowler_role(account_id, management_role_arn)

if __name__ == "__main__":
    main()