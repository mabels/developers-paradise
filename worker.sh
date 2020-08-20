#!/bin/sh
exec su - runner -c 'cd $HOME/actions-runner && bash ./entry-worker.sh'
