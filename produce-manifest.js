/* 
#!/usr/bin/env node
# REPO=$1
# REV=$2

# TAG=$3
# OUTVER=$4
# ARCHS=$5
# 
# REALTAG=${TAG}-${OUTVER}
# if [ -z "$TAG" ]
# then
# 	REALTAG=${OUTVER}
# fi
# cat <<EOF
# image: ${REPO}/developers-paradise:${REALTAG}
# manifests:
# EOF
# for i in $ARCHS 
# do
#    if [ $i = aarch64 ]
#    then
# 	REPOARCH=arm64
#    elif [ $i = armv7l ]
#    then
# 	REPOARCH=arm
#    elif [ $i = x86_64 ]
#    then
# 	REPOARCH=amd64
#    fi
# cat <<EOF
#   -
#     image: ${REPO}/developers-paradise:${TAG}-${i}-${REV}
#     platform:
#       architecture: ${REPOARCH}
#       os: linux
# EOF
# done
# 
*/
const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const YAML = require('yaml');
const fs = require('fs');

/*
# REPO=$1
# REV=$2
# TAG=$3
# OUTVER=$4
# ARCHS=$5
*/

const config = yargs(hideBin(process.argv))
  .option('out', {
    type: 'string',
    default: "/dev/stdout",
    description: "current version"
  })
  .option('app', {
    type: 'string',
    default: "developers-paradise",
    description: "current version"
  })
  .option('repo', {
    demandOption: true,
    type: 'string',
    description: "docker path to repository"
  })
  .option('rev', {
    demandOption: true,
    type: 'string',
    description: "current version"
  })
  .option('imageTag', {
    demandOption: true,
    type: 'string',
    description: "imageTag"
  })
  .option('tag', {
    demandOption: true,
    type: 'string',
    description: "tag"
  })
  .option('arch', {
    demandOption: true,
    type: 'array',
    description: "arch array"
  })
.argv;

const arch2docker = {
	aarch64: "arm64",
	armv7l: "armv7l",
	x86_64: "amd64"
};
// console.log(config)
const manifest = config.arch.map(inArch => {
	const splitArch = inArch.split(":");	
	tag = config.tag;
	if (splitArch.length != 1) {
		tag = splitArch.slice(1).join(":");
	}
	arch = splitArch[0];
	return {
		image: `${config.repo}/${config.app}:${tag}-${arch}-${config.rev}`,
		platform: {
		  architecture: `${arch2docker[arch] || arch}`
		}
	};
}); 
const out = { 
	image: `${config.repo}/developers-paradise:${config.imageTag}`,
	manifest
};

fs.writeFileSync(config.out, YAML.stringify(out));

