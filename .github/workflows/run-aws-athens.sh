#!/bin/bash

set -e

PROJECT=developers-paradise
REGION=eu-central-1
ATHENS_S3_BUCKET=${1:-developers-paradise-athens-cache}
EC2_WORKER=ec2.athens.worker

function getAmi {
  aws ssm get-parameter \
    --region $REGION \
    --name '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64' \
    --query 'Parameter.Value' \
    --output text
}

function ensureSecurityGroupPort {
  local SG_ID="$1"
  local PORT="$2"
  # Allow intra-SG traffic on the given port so workers can reach Athens
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port $PORT \
    --source-group $SG_ID 2>/dev/null || true
}

SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=${PROJECT}-ec2-github-runner" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  echo "Security group ${PROJECT}-ec2-github-runner not found — run the worker script first"
  exit 1
fi

ensureSecurityGroupPort "$SG_ID" 3000

AMI=$(getAmi)
if [ -z "$AMI" ] || [ "$AMI" = "None" ]; then
  echo "Could not find AMI"
  exit 1
fi
echo "Using AMI: $AMI  SG: $SG_ID"

cat > athens-user-data <<USERDATA
#!/bin/bash -x
export HOME=/root
BUCKET=${ATHENS_S3_BUCKET}
REGION=${REGION}

# Amazon Linux 2023 — aws cli v2 and docker are pre-available
dnf update -y
dnf install -y docker jq
systemctl enable docker
systemctl start docker

# Create S3 bucket if it does not exist
if ! aws s3api head-bucket --bucket \$BUCKET --region \$REGION 2>/dev/null; then
  aws s3api create-bucket \
    --bucket \$BUCKET \
    --region \$REGION \
    --create-bucket-configuration LocationConstraint=\$REGION
  aws s3api put-bucket-lifecycle-configuration \
    --bucket \$BUCKET \
    --lifecycle-configuration '{
      "Rules": [{
        "ID": "expire-after-1-year",
        "Status": "Enabled",
        "Filter": {"Prefix": ""},
        "Expiration": {"Days": 365}
      }]
    }'
  echo "Bucket \$BUCKET created with 1-year lifecycle policy"
else
  echo "Bucket \$BUCKET already exists"
fi

# IMDSv2 token for instance metadata
IMDS_TOKEN=\$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=\$(curl -sf -H "X-aws-ec2-metadata-token: \$IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Fetch instance role credentials from IMDS and pass explicitly to container
# (avoids Docker credential chain issues — instance lives < credential TTL)
ROLE_NAME=\$(curl -sf -H "X-aws-ec2-metadata-token: \$IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/)
CREDS=\$(curl -sf -H "X-aws-ec2-metadata-token: \$IMDS_TOKEN" \
  "http://169.254.169.254/latest/meta-data/iam/security-credentials/\$ROLE_NAME")

docker run -d \
  --restart=always \
  --name athens \
  -e ATHENS_STORAGE_TYPE=s3 \
  -e AWS_REGION=\$REGION \
  -e ATHENS_S3_BUCKET_NAME=\$BUCKET \
  -e AWS_ACCESS_KEY_ID=\$(echo \$CREDS | jq -r .AccessKeyId) \
  -e AWS_SECRET_ACCESS_KEY=\$(echo \$CREDS | jq -r .SecretAccessKey) \
  -e AWS_SESSION_TOKEN=\$(echo \$CREDS | jq -r .Token) \
  -p 3000:3000 \
  gomods/athens:latest

for i in \$(seq 1 60); do
  if curl -sf http://localhost:3000/healthz; then
    aws ec2 create-tags --region \$REGION --resources \$INSTANCE_ID \
      --tags Key=AthensReady,Value=true
    echo "Athens is ready"
    break
  fi
  sleep 5
done
USERDATA

aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI \
  --instance-type c5.xlarge \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
  --user-data file://./athens-user-data \
  --security-group-ids $SG_ID \
  --key-name openpgp \
  --associate-public-ip-address \
  --instance-initiated-shutdown-behavior terminate \
  --iam-instance-profile Name=${PROJECT}-ec2-github-runner \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=athens-cache},{Key=Project,Value=${PROJECT}}]" \
  > $EC2_WORKER

ATHENS_IP=$(jq -r '.Instances[0].PrivateIpAddress' $EC2_WORKER)
ATHENS_INSTANCE_ID=$(jq -r '.Instances[0].InstanceId' $EC2_WORKER)

echo "Athens instance: $ATHENS_INSTANCE_ID  private IP: $ATHENS_IP"
echo "aws ec2 terminate-instances --region ${REGION} --instance-ids ${ATHENS_INSTANCE_ID}" > shutdown.$EC2_WORKER

# Write IP so the caller (build-docker.yaml) can pass it to the workers
echo "$ATHENS_IP" > athens.ip
