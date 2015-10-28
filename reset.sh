#!/bin/sh

../fast_perforce_setup/stop_perforce_server.sh
sleep 1.5
rm -rf server_data
rm -rf wc
