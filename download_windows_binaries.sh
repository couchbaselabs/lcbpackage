#!/bin/sh
ARCHES="x86 amd64"
VCVERS="9 10 11 14"
URIBASE="http://172.23.99.199/job/lcb-win32-cmake"
LCBVERS=$1

for arch in $ARCHES; do
    for vers in $VCVERS; do
        url="$URIBASE/ARCH=$arch,MSVCC_VER=$vers,label=windows-builder/ws/BUILD"
        url="${url}/libcouchbase-${LCBVERS}_${arch}_vc${vers}.zip"
        echo $url
        wget "$url"
    done
done
