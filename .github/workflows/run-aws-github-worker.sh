#!/bin/bash

function getAmi {
  aws ec2 describe-images --region eu-central-1 --filters \
  "Name=architecture,Values=$1" \
  'Name=is-public,Values=true' \
  'Name=owner-alias,Values=amazon' \
  'Name=root-device-type,Values=ebs' \
  'Name=virtualization-type,Values=hvm' \
  'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*-server*' \
  --query 'sort_by(Images,&CreationDate)[-1]'
}

function ensureSecurityGroup {
  local SG_NAME="${1}"
  local REGION="${2:-eu-central-1}"
  
  # Check if security group exists
  local SG_ID=$(aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
  
  if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "Security group $SG_NAME exists with ID: $SG_ID" >&2
    echo $SG_ID
    return 0
  fi
  
  # Get default VPC ID
  local VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters 'Name=is-default,Values=true' --query 'Vpcs[0].VpcId' --output text)
  
  if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
    echo "Error: No default VPC found" >&2
    return 1
  fi
  
  # Create security group
  echo "Creating security group: $SG_NAME in VPC: $VPC_ID" >&2
  SG_ID=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name $SG_NAME \
    --description "Security group for EC2 GitHub runners" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
  
  if [ -z "$SG_ID" ]; then
    echo "Error: Failed to create security group" >&2
    return 1
  fi
  
  echo "Created security group: $SG_ID" >&2
  
  # Add SSH rule for IPv4
  echo "Adding SSH rule for IPv4..." >&2
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "IPv4 SSH rule may already exist" >&2
  
  # Add SSH rule for IPv6
  echo "Adding SSH rule for IPv6..." >&2
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,Ipv6Ranges='[{CidrIpv6=::/0,Description="SSH access IPv6"}]' 2>/dev/null || echo "IPv6 SSH rule may already exist" >&2
  
  echo $SG_ID
}


PROJECT=developers-paradise
USER=mabels
REV=$1
if [ -z "$REV" ]
then
  echo "please set the REV"
  exit 1
fi
ARCH=$2
if [ -z "$ARCH" ]
then
   ARCH=$(uname -m)
fi
INSTANCE_TYPE=$3
AMI=$4
DOCKER_TAG=$5
NECKLESS_URL=$6
EC2_WORKER=ec2.$ARCH.$REV.worker
if [ ! -z "$INSTANCE_TYPE" ]
then
   echo Use $INSTANCE_TYPE - $ARCH
elif [ $ARCH = "x86_64" ]
then
   INSTANCE_TYPE=m5ad.large
   INSTANCE_TYPE=c5ad.2xlarge
   #[ -z "$AMI" ] && AMI=ami-0d527b8c289b4af7f
   [ -z "$AMI" ] && AMI=$(getAmi x86_64 | jq -r .ImageId)
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-latest
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.12/neckless_0.1.12_Linux_x86_64.tar.gz
elif [ $ARCH = "aarch64" ]
then
   INSTANCE_TYPE=m6gd.large
   INSTANCE_TYPE=c6gd.2xlarge
   #[ -z "$AMI" ] && AMI=ami-0b168c89474ef4301
   [ -z "$AMI" ] && AMI=$(getAmi arm64 | jq -r .ImageId)
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-latest
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.12/neckless_0.1.12_Linux_arm64.tar.gz
else
   echo "the is no INSTANCE_TYPE known for the arch $ARCH"
   exit 1
fi
if [ -z "$AMI" ]
then
   echo "the is no AMI for $INSTANCE_TYPE known for the arch $ARCH"
   exit 1
fi
if [ -z "$DOCKER_TAG" ]
then
   echo "the is no DOCKER_TAG for $INSTANCE_TYPE known for the arch $ARCH"
   exit 1
fi
if [ -z "$NECKLESS_URL" ]
then
   echo "the is no NECKLESS_URL for $INSTANCE_TYPE known for the arch $ARCH"
   exit 1
fi


cat > user-data <<EOF
#!/bin/bash -x
export HOME=/root

mkfs.ext4 /dev/nvme1n1
mount /dev/nvme1n1 /mnt

mkdir -p /mnt/snap /var/snap
mkdir -p /mnt/docker /var/lib/docker
mkdir -p /mnt/containerd /var/lib/containerd

mv /var/snap /var/snap-off
mkdir -p /var/snap
mount --bind /mnt/snap /var/snap
rsync -vaxH /var/snap-off/ /var/snap/


mv /var/lib/containerd /var/lib/containerd-off
mkdir -p /var/lib/containerd
mount --bind /mnt/containerd /var/lib/containerd
rsync -vaxH /var/lib/containerd-off/ /var/containerd/


mv /var/lib/docker /var/lib/docker-off
mkdir -p /var/lib/docker
mount --bind /mnt/docker /var/lib/docker
rsync -vaxH /var/lib/docker-off/ /var/lib/docker/

systemctl daemon-reload
systemctl stop docker.service

apt update -y
apt upgrade -y


apt install -y ca-certificates curl jq awscli
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<MYEOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
MYEOF

apt update -y

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

aws sts get-caller-identity
curl -L -o /tmp/neckless.tar.gz $NECKLESS_URL
(cd /tmp && tar xvzf neckless.tar.gz)
cp /tmp/neckless /usr/bin

GITHUB_ACCESS_TOKEN=$GITHUB_ACCESS_TOKEN
ARCH=$ARCH
REV=$REV
USER=$USER
PROJECT=$PROJECT
DOCKER_TAG=$DOCKER_TAG

$(cat ./.github/workflows/start-github-worker.sh.template)
EOF

cat > spot.json <<EOF
{
    "MarketType": "spot",
    "SpotOptions": {
      "MaxPrice": "string",
      "SpotInstanceType": "one-time"|"persistent",
      "BlockDurationMinutes": integer,
      "ValidUntil": timestamp,
      "InstanceInterruptionBehavior": "hibernate"|"stop"|"terminate"
    }
}
EOF

cat > spot-config.json <<EOF
{
    "IamFleetRole": "arn:aws:iam::973800055156:role/aws-ec2-spot-fleet-tagging-role",
    "AllocationStrategy": "lowestPrice",
    "TargetCapacity": 1,
    "ValidFrom": "2022-05-19T20:13:15.000Z",
    "ValidUntil": "2023-05-19T20:23:00.000Z",
    "TerminateInstancesWithExpiration": true,
    "Type": "maintain",
    "TargetCapacityUnitType": "units",
    "SpotPrice": "40.9447",
    "LaunchSpecifications": [
        {
            "ImageId": "ami-015c25ad8763b2f11",
            "KeyName": "krypton-oneplus",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0bda75060a0810cac",
                        "VolumeSize": 100,
                        "VolumeType": "gp2",
                        "Encrypted": true
                    }
                }
            ],
            "SubnetId": "subnet-ea761282, subnet-b26bc5c8, subnet-29516963",
            "InstanceRequirements": {
                "VCpuCount": {
                    "Min": 4
                },
                "MemoryMiB": {
                    "Min": 8192
                },
                "LocalStorage": "required",
                "TotalLocalStorageGB": {
                    "Min": 100
                },
                "LocalStorageTypes": [
                    "ssd"
                ]
            }
        }
    ]
}
EOF

cat > spot-options.json <<EOF
{
  "MarketType": "spot",
  "SpotOptions": {
    "MaxPrice": "0.02",
    "SpotInstanceType": "one-time"
  }
}
EOF

# Ensure security group exists
SG_ID=$(ensureSecurityGroup "${PROJECT}-ec2-github-runner" "eu-central-1")
if [ -z "$SG_ID" ]; then
  echo "Error: Failed to ensure security group"
  exit 1
fi
echo "Using security group: $SG_ID"

#  --instance-market-options file://./spot-options.json

aws ec2 run-instances \
  --region eu-central-1 \
  --image-id $AMI \
  --ipv6-address-count 1 \
  --instance-type $INSTANCE_TYPE \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
  --user-data file://./user-data \
  --security-group-ids $SG_ID \
  --key-name openpgp \
  --associate-public-ip-address \
  --instance-initiated-shutdown-behavior terminate \
  --iam-instance-profile Name=${PROJECT}-ec2-github-runner > $EC2_WORKER

echo "aws ec2 terminate-instances --region eu-central-1 --instance-ids $(jq -r .Instances[0].InstanceId $EC2_WORKER)" > shutdown.$EC2_WORKER
