#!/bin/sh
PATH=/sbin:/usr/sbin:$PATH 
export PATH
HASZFS=""
mount | grep /var/lib/docker | grep type.zfs
if [ $? = 0 ]
then
	apt install -y zfsutils-linux
	HASZFS="-s zfs"
fi
rm -rf /var/lib/docker/* 
exec env dockerd --mtu 1440 $HASZFS
