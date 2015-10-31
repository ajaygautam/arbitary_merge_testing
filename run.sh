#!/bin/bash

echo Running tests to verify merging behavior for perforce...

source env.sh

# get to the script directory
cd "$(dirname "$0")"

# Recreate perforce environment
./reset.sh
./server.sh

# Abort on any error
set -e

uat_branch_name=UatBase
dev_branch_name=DevBase
config_file_name=belkin.ini

create_dev_branch() {
	if [ -d $dev_branch_name ]; then
		echo Dev branch $dev_branch_name already exists..
	else
		echo Creating dev branch $dev_branch_name
		mkdir $dev_branch_name
		echo  -e "a\n\nb\n\nc\n\nd\n\ne\n" > $dev_branch_name/$config_file_name
		p4 add $dev_branch_name/$config_file_name
		p4 submit -d  "branch_dev_creation"
	fi
}

echo "==== Start running the test ===="

cd wc

# Create a DevBase branch
create_dev_branch

# Create a UatBase branch - from the dev branch
p4 integrate //depot/$dev_branch_name/... //depot/$uat_branch_name/...
p4 resolve -am -Ac $uat_branch_name
p4 submit -d  "Uat branch created"
p4 sync

diff -r $dev_branch_name $uat_branch_name


# Make 10 mods to Dev, merge each to Uat
# Verify Dev and Uat are in sync (nothing to merge. No ghost merges)
# Create 5 clients. Make Uat and Prod branches for each
# ====> Every week - add new client - migrate from Uat and create prod
# Week 1 - Make 3 changes to dev. Merge all to Uat
# Week 2 - Make 5 changes to dev. Merge all to Uat
# Verify dev and uat are "in sync"
# Roll out all changes to all client's uat and prod
# Verify dev and uat are "in sync"
# Week 3 - Make 3 changes to dev. Merge all to Uat
# Week 4 - Make 5 changes to dev. Merge all to Uat
# Verify dev and uat are "in sync"
# Roll out all changes to even indexed client's uat and prod
# Week 5 - Make 3 changes to dev. Merge all to Uat
# Week 6 - Make 5 changes to dev. Merge all to Uat
# Verify dev and uat are "in sync"
# Roll out all changes to odd indexed client's uat and prod
# Week 7 - Make 3 changes to dev. Merge all to Uat
# Week 8 - Make 5 changes to dev. Merge all to Uat
# Verify dev and uat are "in sync"
# Roll out all changes to all client's uat and prod
# Verify dev and uat are "in sync"
# Make a change in one client (random indexed) prod file
# Merge change to client's uat
# Merge change to uat base
# Merge change to dev base
# Start from week 1
# Run the above 500 times


echo ==== COMPLETED SUCCESSFULLY =====
