#!/bin/sh
PATH=/usr/local/bin:/sbin:/usr/sbin:$PATH 
export PATH
exec env amazon-ssm-agent
