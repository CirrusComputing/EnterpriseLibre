#!/bin/sh
#
# When a new physical server is being configured, it will ask for a puppet cert.
# We sign all requests. 
#
# What are the security implications? Maybe we should first check that the request is coming from a new server inside our domain.
# Mar 2013 RWL

while true; do 
  sleep 5
  /usr/bin/puppet cert sign --all > /dev/null 2>&1
done

