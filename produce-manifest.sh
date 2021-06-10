REPO=$1
REV=$2
OUTVER=$3
ARCHS=$4
cat <<EOF
image: ${REPO}/developers-paradise:${OUTVER}
manifests:
EOF
for i in $ARCHS 
do
   if [ $i = aarch64 ]
   then
	REPOARCH=arm64
   elif [ $i = armv7l ]
   then
	REPOARCH=arm
   elif [ $i = x86_64 ]
   then
	REPOARCH=amd64
   fi
cat <<EOF
  -
    image: ${REPO}/developers-paradise:codeserver-${i}-${REV}
    platform:
      architecture: ${REPOARCH}
      os: linux
EOF
done

