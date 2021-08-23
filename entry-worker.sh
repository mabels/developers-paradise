#!/bin/bash

#id
#env
export HOME=/home/runner
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm use lts/fermium
mkdir -p $HOME/bin
export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ ! -z "$RUNNER_COUNT" -a $RUNNER_COUNT -gt 1 ] 
then
	for i in `seq 2 1 $RUNNER_COUNT`
	do
          RUNNER_NAME=`hostname`-$i RUNNER_WORK_DIRECTORY=_work-$i bash ./start-worker.sh &
	done
fi
exec bash ./start-worker.sh
