#!/bin/bash

### This script validates whether the policies are created correctly on the customer S3 policy and KMS key
### validate S3 bucket Policy
### validate kms key policy

### Ensure you are using the correct aws profile and region
### Ensure you are using the latest aws cli
### ./validate-logging-policies-c.sh

# shellcheck disable=SC2162
read -p "Enter pega Service IAM Role ARN you want to trust: " pegaRoleArn
read -p "Enter your S3 logs bucket name: " bucketName
read -p "Enter your KMS ARN to encrypt your logs bucket: " kmsKeyArn


###############
## Bucket Policy
###############
echo -e "\n==== Check S3 bucket policy ===="
bucketPolicy=$(aws s3api get-bucket-policy --bucket "${bucketName}" --query Policy --output text | jq -r '.Statement[] | select(.Principal.AWS == "'"$pegaRoleArn"'")')
#echo $bucketPolicy
if [ -z "${bucketPolicy}" ]; then
  echo "Fail: No principal match for $pegaRoleArn"
else
  echo "Pass: Found principal match"
fi

putAction=$(jq '.Action | any(. == "s3:PutObject")' <<< "$bucketPolicy")
putAclAction=$(jq '.Action | any(. == "s3:PutObjectAcl")' <<< "$bucketPolicy")

if $putAction && $putAclAction; then
  echo "Pass: Found actions match in the bucket policy"
else
  echo "Fail: Found actions mismatch in the bucket policy"
fi

bucketArn="arn:aws:s3:::$bucketName"
bucketArnWild="arn:aws:s3:::$bucketName/*"
resource=$(jq '.Resource | any(. == "'"$bucketArn"'")' <<< "$bucketPolicy")
resourceWild=$(jq '.Resource | any(. == "'"$bucketArnWild"'")' <<< "$bucketPolicy")
if $resource && $resourceWild; then
  echo "Pass: Found resource match in the bucket policy"
else
  echo "Fail: Resource mismatch in the bucket policy"
fi


###############
## Inspect Key 
###############
#oIFS="$IFS"
IFS=':'
read -ra newarr <<< "$kmsKeyArn"
region="${newarr[3]}"
unset IFS

echo -e "\n==== Check S3 bucket encryption ===="
kmsKeyArnFound=$(aws s3api get-bucket-encryption --bucket "${bucketName}" | jq -r ".ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID")
if [ -z "${kmsKeyArn}" ]; then
	echo "Fail: expected bucket to be encrypted with kms key, but found: ${kmsKeyArnFound}"
elif [[ "$kmsKeyArnFound" != "$kmsKeyArn" ]]; then 
	echo "Fail: kms key found doesn't match ${kmsKeyArn}"
else
	echo "Pass: Bucket is encrypted with expected kms key"
fi

enabled=$(aws kms describe-key --key-id "${kmsKeyArn}" --region "${region}" | jq -r '.KeyMetadata.Enabled')
if $enabled; then
	echo "Pass: kms key is enabled"
else
	echo "Fail: expected kms key is enabled, but found: $enabled"
fi

encryptionAlgorithm=$(aws kms describe-key --key-id "${kmsKeyArn}" --region "${region}" | jq -r '.KeyMetadata.CustomerMasterKeySpec')
if [[ "$encryptionAlgorithm" == "SYMMETRIC_DEFAULT" ]]; then
	echo "Pass: kms key is symmetric"
else
	echo "Fail: Expected kms key to be symmetric, but found: $encryptionAlgorithm"
fi


###############
## KMS Policy 
###############
echo -e "\n==== Check KMS Key policy ===="
sleep 1

kmsPolicy=$(aws kms get-key-policy --policy-name default --key-id "${kmsKeyArn}" --region "${region}" --query Policy --output text | jq -r '.Statement[] | select(.Resource == "'"$kmsKeyArn"'")')
#echo "$kmsPolicy"

if [ -z "${kmsPolicy}" ]; then
	echo "Fail: No kms policy found for resource: $kmsKeyArn"
else
  echo "Pass: kms policy does exist on the provided KMS key"
fi

principalMatch=false
type=$(jq '.Principal.AWS | type' <<< "$kmsPolicy")
if [[ $type == \"array\" ]]; then
  principalMatch=$(jq '.Principal.AWS | any(. == "'"$pegaRoleArn"'")' <<< "$kmsPolicy")
else
  principal=$(jq '.Principal.AWS' <<< "$kmsPolicy")
  if [[ $principal == \"$pegaRoleArn\" ]]; then
    principalMatch=true
  fi
fi

if $principalMatch; then
    echo "Pass: kms policy principal match"
else
  	echo "Fail: kms policy principal mismatch, found: $principal but expecting $pegaRoleArn"
fi


action=$(jq '.Action' <<< "$kmsPolicy")
if [[ "$action" == \"kms:GenerateDataKey*\" ]]; then
	echo "Pass: kms policy action:GenerateDataKey* match"
else
	echo "Fail: kms policy action match, found: $action"
fi


echo -e "\n==== Completed validation ===="




