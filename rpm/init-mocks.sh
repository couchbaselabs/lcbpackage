set -x
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

. $SCRIPTPATH/../common/vars.sh

for RELNO in $RPM_RELNOS
do
    for ARCH in $RPM_ARCHES
    do
        /usr/bin/mock -r lcb-el$RELNO-$ARCH $@
    done
done
