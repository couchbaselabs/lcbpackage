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

VERNUM=
get_version() {
    name=$1
    if [ $name = 'precise' ]; then VERNUM='12.04';
    elif [ $name = 'trusty' ]; then VERNUM='14.04';
    elif [ $name = 'wheezy' ]; then VERNUM='deb7';
    else
        echo "Unknown distribution name $name"
        exit 1
    fi
}

DEB_REPO=$LCB_REPO_PREFIX/ubuntu
rm -rf $DEB_REPO
mkdir -p $DEB_REPO
mkdir -p $DEB_REPO/pool
mkdir -p $DEB_REPO/conf

for DIST in $DEB_DISTROS; do
    srcdir=LCBPACKAGE-DEB/DIST/$DIST
    mkdir -p $DEB_REPO/dists/$DIST
    get_version $DIST
    # Write out the repository metadata:
    cat <<EOF >> $DEB_REPO/conf/distributions
Origin: couchbase
SignWith: $APT_GPG_KEY
Suite: $DIST
Codename: $DIST
Version: $VERNUM
Components: $DIST/main
Architectures: amd64 i386 source
Description: Couchbase package repository

EOF
    # Now that we've written the file, it's time to copy in
    # the proper files. First create the repository layout:
    for chfile in $srcdir/*.changes; do
        reprepro -T deb -VVV --ignore=wrongdistribution -b $DEB_REPO \
            include $DIST $chfile
    done
done
