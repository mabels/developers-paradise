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
if [ ! -z "$INSTANCE_TYPE" ]
then
   echo Use $INSTANCE_TYPE - $ARCH
elif [ $ARCH = "x86_64" ]
then
   INSTANCE_TYPE=m5ad.large 
   [ -z "$AMI" ] && AMI=ami-0d527b8c289b4af7f
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-x86_64-a88149a-534d8baf
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.12/neckless_0.1.12_Linux_x86_64.tar.gz
elif [ $ARCH = "aarch64" ]
then
   INSTANCE_TYPE=m6gd.large
   [ -z "$AMI" ] && AMI=ami-0b168c89474ef4301
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-aarch64-a88149a-f639e813
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
apt update -y
apt upgrade -y
apt install -y awscli jq curl
aws sts get-caller-identity
curl -L -o /tmp/neckless.tar.gz $NECKLESS_URL
(cd /tmp && tar xvzf neckless.tar.gz)
cp /tmp/neckless /usr/bin
export NECKLESS_PRIVKEY=\$(aws --region eu-central-1 secretsmanager get-secret-value \
  --secret-id arn:aws:secretsmanager:eu-central-1:973800055156:secret:developers-paradise/neckless-PzSfaq \
  --query SecretString --output text | jq -r '."developers-paradise"')
curl -L -o .neckless https://raw.githubusercontent.com/mabels/developers-paradise/main/.neckless
eval \$(neckless kv ls GITHUB_ACCESS_TOKEN --shKeyValue)
env > /tmp/out
ls -la .neckless >> /tmp/out
neckless kv ls GITHUB_ACCESS_TOKEN --shKeyValue >> /tmp/out 2>&1
mkfs.ext4 /dev/nvme1n1
mv /var/snap /var/snap-off
mkdir -p /var/snap
mount /dev/nvme1n1 /var/snap
cd /var/snap 
rsync -vaxH /var/snap-off/ .
snap install docker
while true
do
   sleep 5
   docker run -v /run/docker.sock:/run/docker.sock -e GITHUB_ACCESS_TOKEN=\$GITHUB_ACCESS_TOKEN -e RUNNER_NAME=dp-$ARCH-$REV -e RUNNER_LABELS=$REV -e RUNNER_REPOSITORY_URL=https://github.com/mabels/developers-paradise public.ecr.aws/mabels/developers-paradise:$DOCKER_TAG su runner -c 'cd /home/runner/actions-runner &&  /home/runner/actions-runner/start-worker.sh ./run.sh' && exit 0
done
EOF

aws ec2 run-instances \
	--image-id $AMI \
	--instance-type $INSTANCE_TYPE \
	--user-data file://./user-data \
        --security-group-ids sg-01eeff3ca295f3fda \
	--key-name krypton-oneplus \
	--associate-public-ip-address \
	--iam-instance-profile Name=Neckless

