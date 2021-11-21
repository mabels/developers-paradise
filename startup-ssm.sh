#!/bin/sh
PATH=/usr/local/bin:/sbin:/usr/sbin:$PATH 
export PATH

export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm use lts/gallium

exec env amazon-ssm-agent
