# Arbitary Merge Testing
Testing arbitrary merges across branches to prove a version control system can handle years of changes across branches! This is an extension of [Paul Hammant's](http://paulhammant.com/) [subversion testing](https://github.com/paul-hammant/subversion_testing)

## Why?
This is part of a system to prove suitability of a version control system as backing store for a [configuraton as code](http://paulhammant.com/categories.html#configuration_as_code) implementation.

## Systems
This is purely to validate perforce. Subversion has been ruled out due to [merge limitations](http://paulhammant.com/categories.html#source-control). Git has been ruled out due to lack of fine grained authz controls.

## Running
Checkout https://github.com/paul-hammant/fast_perforce_setup alongside the current repo. Then run `run-the-tests.sh`

Do remember to download all the p4 binaries and add them to path, unless you already have them. Helper script: `fast_perforce_setup/get_binaries.sh`

## Documentation: Branch setup
* Branch: DevBase - All changes/config items start here
* Branch: UatBase - All changes move from DevBase out here, where they are propagates to all client UAT environments
* Branch: Testing/Ajay/Uat - Config for personal UAT environments for testing / staging / etc.
* Branch: Clients/CLIENT1/Uat - Client specific Uat config for the client's UAT environment
* Branch: Clients/CLIENT2/Prod - Client specifc Prod config for the client's PROD environment

## Documentation: The "test"
* Create a DevBase branch - Add 3 files - xml, json, csv
* Create a UatBase branch - from the dev branch
* Make 10 mods to Dev, merge each to Uat
* Verify Dev and Uat are in sync (nothing to merge. No ghost merges)
* Create 5 clients. Make Uat and Prod branches for each
* ====> Every week - add new client - migrate from Uat and create prod
* Week 1 - Make 3 changes to dev. Merge all to Uat
* Week 2 - Make 5 changes to dev. Merge all to Uat
* Verify dev and uat are "in sync"
* Roll out all changes to all client's uat and prod
* Verify dev and uat are "in sync"
* Week 3 - Make 3 changes to dev. Merge all to Uat
* Week 4 - Make 5 changes to dev. Merge all to Uat
* Verify dev and uat are "in sync"
* Roll out all changes to even indexed client's uat and prod
* Week 5 - Make 3 changes to dev. Merge all to Uat
* Week 6 - Make 5 changes to dev. Merge all to Uat
* Verify dev and uat are "in sync"
* Roll out all changes to odd indexed client's uat and prod
* Week 7 - Make 3 changes to dev. Merge all to Uat
* Week 8 - Make 5 changes to dev. Merge all to Uat
* Verify dev and uat are "in sync"
* Roll out all changes to all client's uat and prod
* Verify dev and uat are "in sync"
* Make a change in one client (random indexed) prod file
* Merge change to client's uat
* Merge change to uat base
* Merge change to dev base
* Start from week 1
* Run the above 500 times

