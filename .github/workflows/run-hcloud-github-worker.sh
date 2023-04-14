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
HCLOUD_WORKER=hcloud.$ARCH.$REV.worker
if [ ! -z "$INSTANCE_TYPE" ]
then
   echo Use $INSTANCE_TYPE - $ARCH
elif [ $ARCH = "x86_64" ]
then
   INSTANCE_TYPE=cpx31
   [ -z "$AMI" ] && AMI="ubuntu-22.04"
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-latest
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.15/neckless_0.1.15_Linux_x86_64.tar.gz
elif [ $ARCH = "aarch64" ]
then
   INSTANCE_TYPE=cax31
   [ -z "$AMI" ] && AMI="ubuntu-22.04"
   [ -z "$DOCKER_TAG" ] && DOCKER_TAG=ghrunner-latest
   [ -z "$NECKLESS_URL" ] && NECKLESS_URL=https://github.com/mabels/neckless/releases/download/v0.1.15/neckless_0.1.15_Linux_arm64.tar.gz
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


cat > ./user-data <<EOF
#!/bin/bash -x
export HOME=/root

apt update -y
apt upgrade -y
apt install -y jq curl docker.io

GITHUB_ACCESS_TOKEN=$GITHUB_ACCESS_TOKEN
ARCH=$ARCH
REV=$REV
USER=$USER
PROJECT=$PROJECT
DOCKER_TAG=$DOCKER_TAG

$(cat ./.github/workflows/start-github-worker.sh.template)
EOF

hcloud server create \
   --image $AMI \
   --type $INSTANCE_TYPE \
   --ssh-key meno \
   --user-data-from-file ./user-data \
   --name gh-runner-$INSTANCE_TYPE-$REV && \
   echo "gh-runner-$INSTANCE_TYPE-$REV" > $HCLOUD_WORKER

echo "hcloud server delete $(cat $HCLOUD_WORKER)" > shutdown.$HCLOUD_WORKER