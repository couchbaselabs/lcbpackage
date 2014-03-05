set -x
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

. $SCRIPTPATH/../common/vars.sh

RESDIR=$PWD/DIST
mkdir -p $RESDIR

for RELNO in $RPM_RELNOS
do
    for ARCH in $RPM_ARCHES
    do
        CUR_RESDIR=$RESDIR/el$RELNO
        /usr/bin/mock \
            -r lcb-el$RELNO-$ARCH \
            --rebuild \
            --resultdir="$CUR_RESDIR" $@
    done
done
