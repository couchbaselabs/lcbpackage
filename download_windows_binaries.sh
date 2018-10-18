#!/bin/sh
ARCHES="x86 amd64"
VCVERS="9 10 11 14"
URIBASE="http://sdkbuilds.sc.couchbase.com/job/lcb-win32-cmake"
LCBVERS=$1

for arch in $ARCHES; do
    for vers in $VCVERS; do
        url="$URIBASE/ARCH=$arch,MSVCC_VER=$vers,label=windows-builder/ws/BUILD"
        url="${url}/libcouchbase-${LCBVERS}_vc${vers}_${arch}.zip"
        echo $url
        wget "$url"
    done
done
