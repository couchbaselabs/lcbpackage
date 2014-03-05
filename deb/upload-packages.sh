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

for DIST in lucid oneiric precise; do
    cd $TOPDIR/DIST/$DIST
    rake -f $RAKEFILE builder:deb:upload:$DIST
done
