#!/bin/sh

../fast_perforce_setup/stop_perforce_server.sh || echo Ignoring failure to stop server
sleep 1.5
if [ -d server_data ]; then
  rm -rf server_data
fi
if [ -d wc ]; then
  rm -rf wc
fi
