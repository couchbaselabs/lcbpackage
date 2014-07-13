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
        if [ -n "$RPM_ONLY_ARCH" -a "$RPM_ONLY_ARCH" != "$ARCH" ]; then
            echo "Skipping. $RPM_ONLY_ARCH != $ARCH"
            continue
        fi
        if [ -n "$RPM_ONLY_RELNO" -a "$RPM_ONLY_RELNO" != "$RELNO" ]; then
            echo "Skipping. $RPM_ONLY_RELNO != $RELNO"
            continue
        fi

        if [ $ARCH = "i386" -a $RELNO = "7" ]; then
            echo "EL7 does not have 32 bit builds"
            continue;
        fi
        CUR_RESDIR=$RESDIR/el$RELNO
        /usr/bin/mock \
            -r lcb-el$RELNO-$ARCH \
            --rebuild \
            --resultdir="$CUR_RESDIR" $@
    done
done
