#!/bin/bash

#id
#env
export HOME=/home/runner
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
nvm use lts/gallium
mkdir -p $HOME/bin
export PATH=$HOME/bin:/usr/local/bin:$PATH

if [ ! -z "$RUNNER_COUNT" -a "0$RUNNER_COUNT" -gt 1 ]
then
	for i in `seq 2 1 $RUNNER_COUNT`
	do
          RUNNER_NAME=`hostname`-$i RUNNER_WORK_DIRECTORY=_work-$i bash /home/runner/actions-runner/start-worker.sh ./run.sh &
	done
fi
exec bash /home/runner/actions-runner/start-worker.sh ./run.sh
