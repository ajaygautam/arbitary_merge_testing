#!/bin/bash

uat_branch_name=UatBase
dev_branch_name=DevBase
config_file_name=belkin.ini
dev_file=$dev_branch_name/$config_file_name
client_file=clients.txt
env_uat=Uat
env_prod=Prod

echo Running tests to verify merging behavior for perforce...

source env.sh

# get to the script directory
cd "$(dirname "$0")"

# Recreate perforce environment
./reset.sh
./server.sh

# Abort on any error
set -e

log() {
	msg="$*"
	if [[ "$msg" != "" ]]; then
		echo ===== `date +%H:%M:%S` ===== $msg
	fi
}

get_branch_name() {
	env=$1
	client=$2

	echo "$env/$client"
}

create_dev_branch() {
	log Creating dev branch $dev_branch_name
	mkdir $dev_branch_name
	echo  -e "a\n\nb\n\nc\n\nd\n\ne\n" > $dev_file
	p4 add $dev_file
	p4 submit -d  "branch_dev_creation"
}

merge_all_from_one_branch_to_another() {
	src_branch=$1
	dest_branch=$2

	log merging everything from $src_branch to $dest_branch

	integrate_out=`p4 integrate //depot/$src_branch/... //depot/$dest_branch/... 2>&1`
	if [[ $integrate_out != *"all revision(s) already integrated"* ]]; then
		p4 resolve -am -Ac $dest_branch/*
		p4 submit -d  "Merge to branch"
	fi
	p4 sync
}

verify_branches_same() {
	src_branch=$1
	dest_branch=$2

	log Verifying branches are same: $src_branch and $dest_branch

	# check for file contents
	diff -r $src_branch $dest_branch

	# check for ghost merges!
	p4 integrate //depot/$src_branch/... //depot/$dest_branch/...
	resolve_out=`p4 resolve -am -Ac $dest_branch/* 2>&1`
	if [[ "$resolve_out" != *"no file(s) to resolve"* ]]; then
		log ERROR: Found ghost merges!! Output: {$resolve_out}
		exit 2
	fi
}

update_lines_in_file() {
	file=$1

	p4 open $file
	perl -pi -e 's/^a/a !!/' $file
	p4 submit -d "line a changed again"
	p4 open $file
	perl -pi -e 's/^b/b !!/' $file
	p4 submit -d "line b changed again"
	p4 open $file
	perl -pi -e 's/^c/c !!/' $file
	perl -pi -e 's/^d/d !!/' $file
	perl -pi -e 's/^e/e !!/' $file
	p4 submit -d "lines changed again"
}

merge_uatbase_to_client_uat_and_prod() {
	client=$1

	client_uat_branch=`get_branch_name $env_uat $client`
	client_prod_branch=`get_branch_name $env_prod $client`

	merge_all_from_one_branch_to_another $uat_branch_name $client_uat_branch
	merge_all_from_one_branch_to_another $client_uat_branch $client_prod_branch
}

add_new_client() {
	client_number=$1
	if [[ "$client_number" == "" ]]; then
		client_number=$next_client_id
		next_client_id=`expr $next_client_id + 1`
	fi

	client=client$client_number
	echo $client >> $client_file

	merge_uatbase_to_client_uat_and_prod $client

	client_prod_branch=`get_branch_name $env_prod $client`
	verify_branches_same $dev_branch_name $client_prod_branch
}

log Start running the test

cd wc

# Create base branches
create_dev_branch
merge_all_from_one_branch_to_another $dev_branch_name $uat_branch_name
verify_branches_same $dev_branch_name $uat_branch_name

# Make mods to Dev
update_lines_in_file $dev_file
# merge to Uat
merge_all_from_one_branch_to_another $dev_branch_name $uat_branch_name
# Verify Dev and Uat are in sync
verify_branches_same $dev_branch_name $uat_branch_name

# Create 5 clients. Make Uat and Prod branches for each
for i in 1 2 3 4 5
do
	add_new_client $i
done

next_client_id=6

week1() {
	log Running week1

	# make changes to DevBase
	file=$dev_file
	p4 open $file
	perl -pi -e 's/^c/c !!/' $file
	perl -pi -e 's/^d/d !!/' $file
	perl -pi -e 's/^e/e !!/' $file
	p4 submit -d "lines changed again"

	# merge all changes to UatBase
	merge_all_from_one_branch_to_another $dev_branch_name $uat_branch_name

  # new client this week
	add_new_client
}

week2() {
	log Running week2

	# make changes to DevBase
	file=$dev_file
	p4 open $file
	perl -pi -e 's/^a/a !!/' $file
	perl -pi -e 's/^b/b !!/' $file
	p4 submit -d "lines changed again"

	# merge all changes to UatBase
	merge_all_from_one_branch_to_another $dev_branch_name $uat_branch_name
	# Verify Dev and Uat are in sync
	verify_branches_same $dev_branch_name $uat_branch_name

  # new client this week
	add_new_client

	# Roll out all changes to all client's uat and prod
	for client in `cat $client_file`
	do
		merge_uatbase_to_client_uat_and_prod $client

		# Verify things are still in sync
		client_prod_branch=`get_branch_name $env_prod $client`
		verify_branches_same $dev_branch_name $client_prod_branch
	done
}

week1
week2

# ====> Every week - add new client - migrate from Uat and create prod
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


log COMPLETED SUCCESSFULLY
