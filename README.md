
# log-streaming-tools

There are two scripts included in this repo to help customers create and validate required IAM resources in their AWS account in order to receive logs from Pega. For customer to receive logs in their account, a trust relationship needs to be created between Pega referred to as the trusted account and will use 111111111111 as the account number, and the Trusting account which is the customer account hosting the logs bucket and will use 222222222222 as the account number in the examples. The customer creates the role in the trusting account and gives the trusted account permissions to assume the role in the trusting account.

### [Creation Script](create-logging-role.sh)

Creates the required logging IAM role and policies in the customer trusting account. 

**Note:** customer may choose to create the role and policies manually as described in pega documentation.

#### Parameters

* **clusterName:** enter the cluster name provided by pega (trusted account) to customer (trusting account) 
* **guid:** enter the environment unique guid provided by pega(trusted account) to customer (trusting account) 
* **pegaRoleArn:** enter the Pega service IAM Role Arn provided by pega (trusted) to customer(trusting account) 
* **bucketName:** enter the customer logs bucket name (trusting account) 
* **kmsKeyArn:** enter the customer KMS key arn used by customer on S3 bucket (trusting account) 
* **suffixId:** leave blank if re-using same IAM role for all environments. Enter an unique name if the IAM role to be created is different for each of the pega environments. For example, enter dev for IAM role associated with dev environment, prod for production environment and so forth.

#### Example Output
```
// ensure you are signed into your AWS account with correct AWS profile
// execute the script from the terminal and answer the following prompts:

$ ./create-logging-role.sh
$ Enter pega clusterName: {clusterName}
$ Enter pega infinity env GUID: {guid}
$ Enter pega Service IAM Role ARN you want to trust: {pegaRoleArn}
$ Enter your S3 logs bucket name: {bucketName}
$ Enter your KMS ARN to encrypt your logs bucket: {kmsKeyArn}
$ Enter suffix if the IAM role is unique to pega environment such as dev, stg, or prod: {suffixId}

A role created in trusting customer account:
"RoleName": "AllowPegaLogsFrom-{clusterName}" or "RoleName": "AllowPegaLogsFrom-{clusterName}-{suffix}" if suffix was provided.
```

###  [Validation Script](validate-logging-role.sh)

Validates whether the IAM role is created correctly in the trusting account.

#### Parameters
* **guid:** enter the environment unique guid provided by pega(trusted account) to customer (trusting account)
* **pegaRoleArn:** enter the Pega service IAM Role Arn provided by pega (trusted account) to customer (trusting account)
* **roleArnToCheck:** enter the IAM role arn created by customer (trusting account) 
* **bucketName:** enter the customer logs bucket name (trusting account)
* **kmsKeyArn:** enter the customer KMS key arn used by customer on S3 bucket (trusting account) 

#### Example Output
```
// ensure you are signed into your AWS account with correct AWS profile 
// execute the script from the terminal and answer the following prompts: 

$ ./validate-logging-role.sh
$ Enter pega infinity env GUID: {guid}
$ Enter pega Service IAM Role ARN you want to trust:  {pegaRoleArn}
$ Enter your IAM Role ARN:  {roleArnToCheck}
$ Enter your S3 logs bucket name:  {bucketName}
$ Enter your KMS ARN to encrypt your logs bucket:  {kmsKeyArn}

==== Check S3 bucket encryption ==== 
Pass: Bucket is encrypted with expected kms key 
Pass: kms key is enabled 
Pass: kms key is symmetric 

==== Check IAM role Trust Policy ====
Pass: Trust entity principal match 
Pass: GUID condition match 
Pass: s3 permission Resource match 
Pass: s3 write permission Action match 

==== Check KMS Key policy ==== 
Pass: kms policy principal match 
Pass: kms policy action match 
Pass: kms policy resource match 
```
