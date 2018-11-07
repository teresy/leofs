#!/bin/sh

set -xe

# $1: The release tag will be set

. ~/erlang/19.3/activate

# 1. Do packaging
sh make_deb.sh $1 no

# 2. Install the package
dpkg -i leofs_${1}-1_amd64.deb
chsh -s /bin/bash leofs

# 3. start LeoFS
/usr/local/leofs/current/leo_manager_0/bin/leo_manager start
/usr/local/leofs/current/leo_manager_0/bin/leo_manager wait_ready

/usr/local/leofs/current/leo_manager_1/bin/leo_manager start
/usr/local/leofs/current/leo_manager_1/bin/leo_manager wait_ready

/usr/local/leofs/current/leo_storage/bin/leo_storage start
/usr/local/leofs/current/leo_gateway/bin/leo_gateway start
/usr/local/leofs/current/leo_storage/bin/leo_storage wait_ready
/usr/local/leofs/current/leo_gateway/bin/leo_gateway wait_ready

/usr/local/leofs/current/leofs-adm start
/usr/local/leofs/current/leofs-adm add-bucket test 05236

# 4. Upload the package as a release asset with release-id passed by a shell argument
# Refer to https://developer.github.com/v3/repos/releases/#upload-a-release-asset
git clone https://github.com/leo-project/leofs.git
cd leofs
mv ../leofs_${1}-1_amd64.deb leofs_${1}-1_ubuntu-14.04_amd64.deb
hub release edit -m "" -a leofs_${1}-1_ubuntu-14.04_amd64.deb $1
