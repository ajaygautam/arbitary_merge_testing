#!/bin/sh

rm -rf server_data
mkdir server_data

cd server_data
../../fast_perforce_setup/make_perforce_server_ssl_keys.sh
../../fast_perforce_setup/run_perforce_server_localhost.sh
cd ..

sleep 1
echo Server started... waiting for settle down...
sleep 2

../fast_perforce_setup/create-admin-account-and-more-security-stuff.sh
