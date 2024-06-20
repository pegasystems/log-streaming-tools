# log-streaming-tools

There are two scripts included in this repo to help customers create and validate required IAM resources in their AWS account inorder to receive logs from Pega. For customer to receive logs in their account, a trust relationship needs to be created between Pega referred to as the trusted account and will use 111111111111 as the account number, and the Trusting account which is the customer account hosting the logs bucket and will use 222222222222 as the account number in the examples. The customer creates the role in the trusting account and gives the trusted account permissions to assume the role in the trusting account.

#### 1. validate-logging-role.sh
#### 2. create-logging-role.sh
<br />

###  1. Validation script
#### This script validates whether the IAM role is created correctly in the trusting account.
###  How to run the validation script?
// ensure you are signed into your AWS account with correct AWS profile <br />
// execute the script from the terminal and answer the following prompts: <br />
$ ./validate-logging-role.sh <br />
$ Enter pega infinity env GUID: {guid} <br />
$ Enter pega Service IAM Role ARN you want to trust:  {pegaRoleArn} <br />
$ Enter your IAM Role ARN:  {roleArnToCheck} <br />
$ Enter your S3 logs bucket name:  {bucketName} <br />
$ Enter your KMS ARN to encrypt your logs bucket:  {kmsKeyArn} <br />

Where: <br />
{guid}: Enter the environment unique guid provided by pega(trusted account) to customer(trusting account) <br />
{pegaRoleArn}: Enter the Pega service IAM Role Arn provided by pega (trusted account) to customer(trusting account) <br />
{roleArnToCheck}: Enter the IAM role arn created by customer (trusting account) <br />
{bucketName}: Enter the customer logs bucket name (trusting account) <br />
{kmsKeyArn}: Enter the customer KMS key arn used by customer on S3 bucket (trusting account) <br />
<br />

Expected script output: <br />
==== Check S3 bucket encryption ==== <br />
Pass: Bucket is encrypted with expected kms key <br />
Pass: kms key is enabled <br />
Pass: kms key is symmetric <br />

==== Check IAM role Trust Policy ====<br />
Pass: Trust entity principal match <br />
Pass: GUID condition match <br />
Pass: s3 permission Resource match <br />
Pass: s3 write permission Action match <br />

==== Check KMS Key policy ==== <br />
Pass: kms policy principal match <br />
Pass: kms policy action match <br />
Pass: kms policy resource match <br />

<br />

### 2. Creation script
#### This script creates the required logging IAM role and policies in the customer trusting account. Note, customer may choose to create the role and policies manually as described in pega documentation.
###  How to run the creation script?
// ensure you are signed into your AWS account with correct AWS profile <br />
// execute the script from the terminal and answer the following prompts: <br />
$ ./create-logging-role.sh <br />
$ Enter pega clusterName: {clusterName} <br />
$ Enter pega infinity env GUID: {guid} <br />
$ Enter pega Service IAM Role ARN you want to trust: {pegaRoleArn}  <br />
$ Enter your S3 logs bucket name: {bucketName} <br />
$ Enter your KMS ARN to encrypt your logs bucket: {kmsKeyArn} <br />
$ Enter suffix if the IAM role is unique to pega environment such as dev, stg, or prod: {suffixId} <br />

Where: <br />
{clusterName}: Enther the cluster name provided by pega (trusted account) to customer(trusting account) <br />
{guid}: Enter the environment unique guid provided by pega(trusted account) to customer(trusting account) <br />
{pegaRoleArn}: Enter the Pega service IAM Role Arn provided by pega (trusted) to customer(trusting account) <br />
{bucketName}: Enter the customer logs bucket name (trusting account) <br />
{kmsKeyArn}: Enter the customer KMS key arn used by customer on S3 bucket (trusting account) <br />
{suffixId}: Leave blank if re-using same IAM role for all environments. Enter an unique name if the IAM role to be created is different for each of the pega environments. For example, enter dev for IAM role associated with dev environment, prod for production environment and so forth.
<br />

Expected script output: <br />
A role created in trusting customer account: <br /> 
"RoleName": "AllowPegaLogsFrom-{clusterName}" or "RoleName": "AllowPegaLogsFrom-{clusterName}-{suffix}" if suffix was provided.
