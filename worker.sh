#!/bin/sh
exec su -p runner -c 'HOME=/home/runner && cd $HOME/actions-runner && id && bash ./entry-worker.sh ./run.sh'
