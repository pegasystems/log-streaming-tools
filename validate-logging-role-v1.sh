#!/bin/bash

### This script validates whether the IAM role and policies are created correctly for pega logging service to forward logs
### validate Role exists
### validate Role has correct trust relationship
### validate Role has correct policies
### validate kms policy

### ./validate-logging-role.sh 


read -p "Enter pega infinity env GUID: " guid
read -p "Enter pega Service IAM Role ARN you want to trust: " pegaRoleArn
read -p "Enter your IAM Role ARN: " roleArnToCheck
read -p "Enter your S3 logs bucket name: " bucketName
read -p "Enter your KMS ARN to encrypt your logs bucket: " kmsKeyArn


roleNameToCheck="${roleArnToCheck#*/}"
role=$(aws iam list-roles --query 'Roles[*].RoleName' --output table | grep $roleNameToCheck)
if [ -z "${role}" ]; then
	echo "Fail: role doesn't exist"
	exit 1
fi


###############
## Inspect Key 
###############
echo -e "\n==== Check S3 bucket encryption ===="
kmsKeyArnFound=$(aws s3api get-bucket-encryption --bucket ${bucketName} | jq -r ".ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID")
if [ -z "${kmsKeyArn}" ]; then
	echo "Fail: expected bucket to be encrypted with kms key, but found: ${kmsKeyArnFound}"
elif [[ "$kmsKeyArnFound" != "$kmsKeyArn" ]]; then 
	echo "Fail: kms key found doesn't match ${kmsKeyArn}"
else
	echo "Pass: Bucket is encrypted with exepcted kms key"
fi

enabled=$(aws kms describe-key --key-id "${kmsKeyArn}" | jq -r '.KeyMetadata.Enabled')
if $enabled; then
	echo "Pass: kms key is enabled"
else
	echo "Fail: exepcted kms key is enabled, but found: $enabled"
fi


encryptionAlgorithm=$(aws kms describe-key --key-id "${kmsKeyArn}" | jq -r '.KeyMetadata.CustomerMasterKeySpec')
if [[ "$encryptionAlgorithm" == "SYMMETRIC_DEFAULT" ]]; then
	echo "Pass: kms key is symmetric"
else
	echo "Fail: Expected kms key to be symmetric, but found: $encryptionAlgorithm"
fi



#######################################
## IAM Trust Policy and S3 permissions
#######################################
echo -e "\n==== Check IAM role Trust Policy ===="
sleep 3
# Pega Trust Principal 
principal=$(aws iam get-role --role-name ${roleNameToCheck} | jq -r ".Role.AssumeRolePolicyDocument.Statement[0].Principal.AWS")

if [[ "$principal" == "$pegaRoleArn" ]]; then
	echo "Pass: Trust entity principal match"
else
	echo "Fail: Trust Entity Principal Mismatch, but found: $principal"
fi

# external-Id
guid1=$(aws iam get-role --role-name ${roleNameToCheck} | jq -r '.Role.AssumeRolePolicyDocument.Statement[] | select(.Principal.AWS == "'"${pegaRoleArn}"'")'.Condition.StringEquals.'"sts:ExternalId"')

if [[ "$guid1" == "$guid" ]]; then
	echo "Pass: GUID condition match"
else
	echo "Fail: GUID condition mismtach, but found $guid1"
fi


resourceMatch="arn:aws:s3:::${bucketName}/*"
actionMatch="s3:PutObject"
policyResource=$(aws iam get-role-policy --role-name ${roleNameToCheck} --policy-name s3writepolicy | jq -r '.PolicyDocument.Statement[].Resource')
policyAction=$(aws iam get-role-policy --role-name ${roleNameToCheck} --policy-name s3writepolicy | jq -r '.PolicyDocument.Statement[].Action')

if [[ "$policyResource" == $resourceMatch ]]; then
	echo "Pass: s3 permission Resource match"
else
	echo "Fail: s3 Resource mismatch, found: $policyResource"
	echo $resourceMatch
fi

if [[ "$policyAction" == "$actionMatch" ]]; then
	echo "Pass: s3 write permission Action match"
else
	echo "Fail: s3 write permission Action mismatch, found: $policyAction"
fi




###############
## KMS Policy 
###############
echo -e "\n==== Check KMS Key policy ===="
sleep 3

kmsPolicy=$(aws kms get-key-policy --policy-name default --key-id $kmsKeyArn --query Policy --output text | jq -r '.Statement[] | select(.Principal.AWS == "'"${roleArnToCheck}"'" and .Action == "kms:GenerateDataKey*" and .Resource == "'"$kmsKeyArn"'")')
if [ -z "${kmsPolicy}" ]; then
	echo "Fail: No kms policy found"
fi

#echo ${kmsPolicy}

principal="$(jq '.Principal.AWS' <<< "$kmsPolicy")"
action=$(jq '.Action' <<< "$kmsPolicy")
resource=$(jq '.Resource' <<< "$kmsPolicy")

if [[ $principal == \"$roleArnToCheck\" ]]; then
	echo "Pass: kms policy principal match"
else
	echo "Fail: kms policy principal mismatch, found: $principal"
fi

if [[ "$action" == \"kms:GenerateDataKey*\" ]]; then
	echo "Pass: kms policy action match"
else
	echo "Fail: kms policy action match, found: $action"
fi

if [[ "$resource" == \"$kmsKeyArn\" ]]; then
	echo "Pass: kms policy resource match"
else
	echo "Fail: kms policy resource mismatch, found: $resource"
fi


echo -e "\n==== Completed validation ===="




