
# log-streaming-tools
This repository provides tools that support Pega Clients who are leveraging [Pega Cloud's log stream capabilities](https://docs.pega.com/bundle/pega-cloud/page/pega-cloud/pc/pcs-logs-overview.html).

##  [Validation Script](validate-logging-policies.sh)

This script validates customer S3 logs bucket policy and KMS key policy to allow pega logging service to forward logs to the destination customer bucket 

#### Parameters
* **pegaRoleArn:** enter the Pega service IAM Role Arn provided by pega to customer
* **bucketName:** enter the customer logs bucket name
* **kmsKeyArn:** enter the customer KMS key arn used by customer on S3 bucket

#### Example Output
```
// ensure you are signed into your AWS account with correct AWS profile 
// execute the script from the terminal and answer the following prompts: 

$ ./validate-logging-role.sh
$ Enter pega Service IAM Role ARN you want to trust:  {pegaRoleArn}
$ Enter your S3 logs bucket name:  {bucketName}
$ Enter your KMS ARN to encrypt your logs bucket:  {kmsKeyArn}

==== Check S3 bucket policy ====
Pass: Found principal match
Pass: Found actions match
Pass: Found resource match

==== Check S3 bucket encryption ====
Pass: Bucket is encrypted with exepcted kms key
Pass: kms key is enabled
Pass: kms key is symmetric

==== Check KMS Key policy ====
Pass: kms policy does exist on the provided KMS key
Pass: kms policy principal match
Pass: kms policy action:GenerateDataKey* match
```
