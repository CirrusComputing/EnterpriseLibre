#!/bin/bash

# Config
VEID_BASE=1500
ORG=A3
DOMAIN=a3.zoomcomputing.net
SHORT_DOMAIN=a3
NETWORK=10.101.2
IP=192.168.101.2
VZ_BASE_PATH=/var/lib/vz-A3
BRIDGE=br3
HWHOST=server
HWH_IP=10.101.1.1
BACKUP_SERVER=nanook.zoomcomputing.net

DB_OPTION=$1

source /home/c4/bin/cleanup.sh

