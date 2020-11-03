#!/bin/bash
# set noninteractive installation
export DEBIAN_FRONTEND=noninteractive
#update
apt-get update
#install tzdata package
apt-get install -y tzdata
# set your timezone
ln -fs /usr/share/zoneinfo/Europe/Madrid /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
