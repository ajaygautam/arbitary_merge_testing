#!/bin/bash

uat_branch_name=UatBase
dev_branch_name=DevBase
config_file_name=belkin.ini
dev_file=$dev_branch_name/$config_file_name
client_file=clients.txt
env_uat=Uat
env_prod=Prod
number_of_iterations=5

which sponge > /dev/null
if [[ $? -ne 0 ]]; then
	echo This utility needs sponge. please install moreutils
	exit 2
fi

echo Running tests to verify merging behavior for perforce...

source env.sh

# get to the script directory
cd "$(dirname "$0")"

# Recreate perforce environment
./reset.sh
./server.sh

# Abort on any error
set -e

start_time=`date +%H:%M:%S`

log() {
	msg="$*"
	if [[ "$msg" != "" ]]; then
		echo ===== `date +%H:%M:%S` $0 LOG ===== $msg
	fi
}

get_random_using_jot() {
	upper_limit=$1

	jot -r 1 1 $upper_limit
}

get_random_using_shuf() {
	upper_limit=$1

	shuf -n 1 -i 1-$upper_limit
}

# There must be a cleaner / earier way to do this...
get_randomizer_to_use() {
	found=`which jot || echo no_jot`
	if [[ $found == *"no_jot"* ]]; then
		found=`which shuf || echo no_shuf`
		if [[ $found == *"no_shuf"* ]]; then
			log Unable to locate a randomizer. I support jot OR shuf. Get one of these.
			exit 3
		else
			echo get_random_using_shuf
		fi
	else
		echo get_random_using_jot
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
	echo  -e "a\nb\nc\nd\ne\n" > $dev_file
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
	log adding client $client
	echo $client >> $client_file

	merge_uatbase_to_client_uat_and_prod $client

	client_prod_branch=`get_branch_name $env_prod $client`
	verify_branches_same $dev_branch_name $client_prod_branch
}

week1() {
	log next week

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
	log next week

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

week3() {
	week1
}

week4() {
	log next week

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
	skip=1
	for client in `cat $client_file`
	do
		if [[ $skip == 1 ]]; then
			skip=0
		else
			# Roll out all changes to even indexed client's uat and prod
			skip=1
			merge_uatbase_to_client_uat_and_prod $client

			# Verify things are still in sync
			client_prod_branch=`get_branch_name $env_prod $client`
			verify_branches_same $dev_branch_name $client_prod_branch
		fi
	done
}

week5() {
	week1
}

week6() {
	log next week

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
	skip=0
	for client in `cat $client_file`
	do
		if [[ $skip == 1 ]]; then
			skip=0
		else
			# Roll out all changes to odd indexed client's uat and prod
			skip=1
			merge_uatbase_to_client_uat_and_prod $client

			# Verify things are still in sync
			client_prod_branch=`get_branch_name $env_prod $client`
			verify_branches_same $dev_branch_name $client_prod_branch
		fi
	done
}

week7() {
	week1
}

week8() {
	week2
}

run_test_multiple_times() {
	# locate a randomizer
	log locating randomizer
	randomizer=`get_randomizer_to_use`
	log found randomizer: $randomizer
	if [[ "$randomizer" == "" ]]; then
		log Unable to locate a randomizer!
		exit 1
	else
		log using randomizer $randomizer
	fi

	run_index=0
	while [[ $run_index -lt $number_of_iterations ]]; do
		run_index=`expr $run_index + 1`

		log Iteration number: $run_index

		week1
		week2
		week3
		week4
		week5
		week6
		week7
		week8

		# Find a random client
		client_count=`wc -l < clients.txt | tr -d " "`
		random_index=`$randomizer $client_count`
		random_client=`head -n $random_index $client_file | tail -n 1`
		log random client: $random_client

		# Make a change in client's prod file
		client_prod_file=$env_prod/$random_client/$config_file_name
		p4 open $client_prod_file
		perl -pi -e 's/^b/b !!/' $client_prod_file
		p4 submit -d "lines changed again"

		# Merge change to client's uat
		client_uat_branch=`get_branch_name $env_uat $random_client`
		client_prod_branch=`get_branch_name $env_prod $random_client`
		merge_all_from_one_branch_to_another $client_prod_branch $client_uat_branch
		# Merge change to uat base
		merge_all_from_one_branch_to_another $client_uat_branch $uat_branch_name
		# Merge change to dev base
		merge_all_from_one_branch_to_another $uat_branch_name $dev_branch_name
	done
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

# This runs the *meat* of the test!
run_test_multiple_times

log COMPLETED SUCCESSFULLY. Start time: $start_time
