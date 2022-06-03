#!/bin/bash
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
OCI_WORKER=oci.$ARCH.$REV.worker
if [ ! -z "$INSTANCE_TYPE" ]
then
   echo Use $INSTANCE_TYPE - $ARCH
elif [ $ARCH = "x86_64" ]
then
   INSTANCE_TYPE=VM.Optimized3.Flex
   #[ -z "$AMI" ] && AMI=ami-0d527b8c289b4af7f
   [ -z "$AMI" ] && AMI=ocid1.image.oc1.eu-frankfurt-1.aaaaaaaalt2wothtrqva253mkuujx56ciafjkalpa7gsctog2y6vwb2werya 
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-latest
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.12/neckless_0.1.12_Linux_x86_64.tar.gz
elif [ $ARCH = "aarch64" ]
then
   INSTANCE_TYPE=VM.Standard.A1.Flex
   #[ -z "$AMI" ] && AMI=ami-0b168c89474ef4301
   [ -z "$AMI" ] && AMI=ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa7eis5rnrr2tyvwa27ko53yp4ua7jur7xgnhppockzytlsa3soara 
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

apt update -y
apt upgrade -y
apt install -y awscli jq curl docker.io

while true
do
   sleep 5
   docker info > /dev/null
   if [ \$? = 0 ]
   then
   	cat > /tmp/start.sh <<EOF1
#!/bin/bash
chmod 666 /run/docker.sock
docker ps
su runner -c 'docker ps; cd /home/runner/actions-runner && /home/runner/actions-runner/start-worker.sh ./run.sh'
EOF1
	chmod 666 /run/docker.sock
        docker run \
	     -v /run/docker.sock:/run/docker.sock \
	     -v /tmp/start.sh:/tmp/start.sh \
	     -e DOCKER_HOST=unix:///run/docker.sock \
	     -e GITHUB_ACCESS_TOKEN="$GITHUB_ACCESS_TOKEN" \
	     -e RUNNER_NAME="dp-$ARCH-$REV --ephemeral" \
	     -e CONFIG_OPTS="--ephemeral" \
	     -e RUNNER_LABELS="$REV" \
	     -e RUNNER_REPOSITORY_URL=https://github.com/${USER}/${PROJECT} \
	     public.ecr.aws/mabels/developers-paradise:$DOCKER_TAG \
	     bash /tmp/start.sh && \
	 poweroff && \
         exit 0
   fi
done
EOF

# $HOME/user-data is a artefact of docker
oci \
--auth api_key \
compute instance launch  \
--availability-domain Rjsp:EU-FRANKFURT-1-AD-3 \
--subnet-id ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaauzimrxgjorgl27ug3i6hoflyoi4gwlnr7ihiuxgagr4bahmcejyq \
--shape $INSTANCE_TYPE \
--image-id $AMI \
--compartment-id ocid1.tenancy.oc1..aaaaaaaax2n5snd6z7n3ddnnii5x2727bh4zhjzcb7umshzorp4qnp7a2jda \
--shape-config '{"ocpus":4.0,"memoryInGBs":12.0}' \
--assign-public-ip true \
--boot-volume-size-in-gbs 120 \
--user-data-file "$HOME/user-data" \
--is-pv-encryption-in-transit-enabled true \
--metadata '{"ssh_authorized_keys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7BOKHV5d3/cnXsZ23X8d6MT9H/1kn+oT2LRaKtyyKB6iLsEN6Hk2017RyFR98oWXqo5EM5ttL4ZTQNEawqp52KPGujDV7XHvu4/cxfNzjxhOUtJ9j5wOG4qVVvBfcvbFRo1wVuJRe+7uiA9seGU3LZ01ASM+ajEtRY2tLBrwJhY/4q08ghy8gBfFV0LDkY8wH965PYUZButHpJvCz6xTEzVVqeLKobD6jsE0PafgdBuiRC+ErRH0vkVfb5NEoB2UhZB/L9QqeVDEyrKTk2AcxlCa6zcLkcLq5ygel8+MUuW3zBscDQrNxJ09vzBFq0auV+Wq8/ElTJC5eIIYJ1WO88EuoMiG/BCMM75NrUqa6Bn5rgbHNVZAAxo0/qJSV4i7RTE+0OVEDu2jt+wNpWZEmCJ4TNIQyNFmxuRGjQqxHAtSWnkkO/LzOUw8rWCGLvgnrIX8jtRXvNqNnv1lTQ5X97d8TTA55dNkeYUCC4NbeWr49zqcW//36r4KIku48PuU= revealsix"}' \
 > $OCI_WORKER 

#aws ec2 run-instances \
#  --image-id $AMI \
#  --instance-type $INSTANCE_TYPE \
#  --user-data file://./user-data \
#  --security-group-ids $(aws ec2 describe-security-groups | jq ".SecurityGroups[] | select(.GroupName==\"${PROJECT}-ec2-github-runner\") .GroupId" -r) \
#  --key-name ${PROJECT}-ec2-github-manager \
#  --associate-public-ip-address \
#  --instance-initiated-shutdown-behavior terminate \
#  --iam-instance-profile Name=${PROJECT}-ec2-github-runner > $OCI_WORKER

