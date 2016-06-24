#!/bin/sh
#
# Normally this script is started by newPhysServer.pl
#
# Mar 2013 RWL

if [ $# -ne 1 ]; then
  echo Usage: $0 new_server_hostname
  exit 1
fi
#set -x

# identifies the server in the cobbler system
new_server=$1
new_fqdn=$1.serv.virtualorgs.net
# get the internal IP
new_IP=`dig +short $new_fqdn`

# zzz config jari here?

# config nagios 
ssh maui.serv.virtualorgs.net 'cd /etc/nagios3/servers/hw/tools; ./generate $new_server; /etc/init.d/nagios3 reload'

# Insert the new_server_fqdn in the cobbler settings file.
# The proper soluton is to have cobbler manage multiple profiles or systems, but this is simpler
sed -i[sav] -e "s/^hostname: .*\$/hostname: $new_fqdn/" /etc/cobbler/settings
sed -i[sav] -e "s/^hostIP: .*\$/hostIP: $new_IP/" /etc/cobbler/settings

service cobblerd restart
cobbler sync

# remove all old certs just in case we are re-installing a server
puppet cert clean --all
service puppetmaster restart

echo Ready to install $new_server at $new_IP
echo Start PXE by booting the new server
exit 0

# The following mcollective scripting is unnecessary. Puppet is started from the kickstart file.
mco_not_ready=1

while [ $mco_not_ready -gt 0 ]; do 
  echo waiting for new server $new_server to start mcollective
  mco rpc rpcutil agent_inventory -I $new_fqdn

  if [ $? -le 0 ]; then
    echo mcollective puppet is ready
    let mco_not_ready=0
  fi
  sleep 10
done 

echo start new server config $new_server
mco puppet runonce -I $new_fqdn
echo end new server config

echo disable further config by removing cert for $new_server
puppet cert clean $new_fqdn

#------------ end ------------------
