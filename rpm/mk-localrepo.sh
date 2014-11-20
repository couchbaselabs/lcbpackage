#!/bin/bash
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

# Run from repository directory

RAKEFILE=$SCRIPTPATH/../rakefiles/repositories.rake
COMMON=$SCRIPTPATH/../common
TOPDIR=$PWD

. $COMMON/vars.sh

rm -rf $LCB_REPO_PREFIX/rpm
rake -f $RAKEFILE master:rpm:seed

for DIST in $RPM_RELNOS; do
    cd $TOPDIR/LCBPACKAGE-RPM/DIST/el$DIST
    if [ $DIST = "5" ]; then
        rakedist="5.5"
    elif [ $DIST = "6" ]; then
        rakedist="6.2"
    else
        rakedist="7"
    fi
    for pkg in *.rpm
    do
        expect $SCRIPTPATH/sign_rpm.expect $RPM_GPG_KEY $pkg
    done
    rake -f $RAKEFILE builder:rpm:upload:centos$rakedist
done

rake -f $RAKEFILE master:rpm:import
rake -f $RAKEFILE master:rpm:sign
