#!/bin/bash

#
# This script creates an IAM Role in AWS account per environment so that pega logging service can assume it.
# The creation of IAM role and policies is required so that customers can receive logs from Pega into their account
# The creation of the IAM role and policies can be done either manually or via this helper script
#

### ./create-logging-role.sh 

: '
% ./customer-role-dev.sh
Enter pega infinity env GUID: <ENV-GUID>
Enter pega Service IAM Role ARN you want to trust: <PegaLoggingRoleARN>
Enter your S3 logs bucket name: <LogsBucket>
Enter your KMS ARN to encrypt your logs bucket: <CustomerKMSkey-Used On the Bucket>
Enter suffix if the IAM role is unique to pega environment such as dev, stg, or prod: <optional-such as prod>
'


#echo This script provisions IAM role on customer account to trust pega logging service

read -p "Enter pega clusterName: " clusterName
read -p "Enter pega infinity env GUID: " guid
read -p "Enter pega Service IAM Role ARN you want to trust: " pegaRoleArn
read -p "Enter your S3 logs bucket name: " bucketName
read -p "Enter your KMS ARN to encrypt your logs bucket: " kmsKeyArn
read -p "Enter suffix if the IAM role is unique to pega envionment such as dev, stg, or prod: " suffix


#####
##### Customer 
#####
IFS=':'
read -ra newarr <<< "$kmsKeyArn"

region="${newarr[3]}"
accountId="${newarr[4]}"
keyPortion="${newarr[5]}"
keyId="${keyPortion##key/}"


#1 create Role with trust policy
echo "\n1. Create IAM Role with Trust Policy."
customerRoleName="AllowPegaLogsFrom-${clusterName}"

if [ ! -z "${suffix}" ]; then
    customerRoleName+="-${suffix}"
fi

customerRoleArn="arn:aws:iam::"${accountId}":role/"${customerRoleName}

aws iam create-role \
    --role-name ${customerRoleName} \
    --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "sts",
            "Effect": "Allow",
            "Principal": {
                "AWS": "'"${pegaRoleArn}"'"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": [
                        "'"${guid}"'"
                    ]
                }
            }
        }
    ]
}'


#2 attach s3 policy customer role so it can write to the s3 bucket
echo "\n2. Attach S3 permissions policy to IAM role"

aws iam wait role-exists --role-name ${customerRoleName}

sleep 3

aws iam put-role-policy \
    --role-name ${customerRoleName} \
    --policy-name s3writepolicy \
    --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s3",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::'"${bucketName}"'/*"
        }
    ]
}'


#3 Create the KMS Key Policy
echo "\n3. Modify KMS Key policy to allow encrypt/decrypt"

sleep 3

aws kms put-key-policy \
    --policy-name default \
    --key-id ${keyId} \
    --policy '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid" : "st3",
            "Effect" : "Allow",
            "Principal" : {
                "AWS" : "arn:aws:iam::'"${accountId}"':root"
            },
            "Action" : "kms:*",
            "Resource" : "*"
        },
        {
            "Sid": "Enable Logging service KMS Access",
            "Effect": "Allow",
            "Principal": {
                "AWS": "'"${customerRoleArn}"'"
            },
            "Action": "kms:GenerateDataKey*",
            "Resource": "'"${kmsKeyArn}"'"
        }
    ]
}'


