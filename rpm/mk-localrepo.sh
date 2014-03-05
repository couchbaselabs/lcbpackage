#!/bin/bash
set -x
set -e
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

# Run from repository directory

RAKEFILE=$SCRIPTPATH/../rakefiles/repositories.rake
COMMON=$SCRIPTPATH/../common
TOPDIR=$PWD

. $COMMON/vars.sh

rm -rf $LCB_REPO_PREFIX
rake -f $RAKEFILE master:rpm:seed

for DIST in $RPM_RELNOS; do
    cd $TOPDIR/DIST/el$DIST
    if [ $DIST = "5" ]; then
        rakedist="5.5"
    else
        rakedist="6.2"
    fi
    for pkg in *.rpm; do
        yes '' | rpm --resign \
            -D "_signature gpg" \
            -D "_gpg_name $RPM_GPG_KEY" \
            $pkg
        done
    rake -f $RAKEFILE builder:rpm:upload:centos$rakedist
done

rake -f $RAKEFILE master:rpm:import
rake -f $RAKEFILE master:rpm:sign
