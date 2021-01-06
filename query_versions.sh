#!/bin/bash
set -e
set -o pipefail 
for repo in "$@"
do 
	version=$(curl -f --silent "https://${APIUSER}api.github.com/repos/${repo}/releases/latest" | jq -r .tag_name) 
	echo $(echo ${repo} | tr '[a-z]' '[A-Z]' | sed -e 's/\//_/g' -e 's/-//g')_VERSION=${version}
done
