#!/bin/bash
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

# Run from repository directory
COMMON=$SCRIPTPATH/../common
TOPDIR=$PWD
. $COMMON/vars.sh


RPM_REPO=$LCB_REPO_PREFIX/rpm
rm -rf $RPM_REPO

do_distarch() {
    dist=$1;
    arch=$2;
    dist_subdir=
    if [ $dist = '6' ]; then dist_subdir='6.2'; else dist_subdir=$dist; fi
    # Copy the relevant files into the directory
    destdir=$RPM_REPO/$dist_subdir/$arch
    srcdir=$TOPDIR/LCBPACKAGE-RPM/DIST/el$dist
    mkdir -p $destdir
    cp $srcdir/*.src.rpm $destdir
    cp $srcdir/*.$arch.rpm $destdir

    for pkg in $destdir/*.rpm; do
        expect $SCRIPTPATH/sign_rpm.expect $RPM_GPG_KEY $pkg || true
    done

    # Generate the metadata structures
    createrepo --checksum sha $destdir
    gpg --batch --yes -u $RPM_GPG_KEY --detach-sign --armor $destdir/repodata/repomd.xml
}

for DIST in $RPM_RELNOS; do
    for ARCH in $RPM_ARCHES; do
        if [ $ARCH = 'i386' ]; then
          if [ $DIST = '7' ]; then
            continue;
          else
            ARCH=i686
          fi
        fi
        do_distarch $DIST $ARCH
    done
done
