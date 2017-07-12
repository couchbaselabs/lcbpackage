set -x
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

. $SCRIPTPATH/../common/vars.sh

PARSE_SCRIPT=$SCRIPTPATH/../git-describe-parse/parse-git-describe.pl
TARNAME=libcouchbase-$( $PARSE_SCRIPT --tar)
VERSION=$( $PARSE_SCRIPT --rpm-ver)
RELEASE=$( $PARSE_SCRIPT --rpm-rel)

# Create the Build directory
WORKSPACE=$PWD/LCBPACKAGE-RPM
SRCDIR=$PWD

rm -rf $WORKSPACE
mkdir $WORKSPACE
cd $WORKSPACE

../cmake/configure --disable-plugins --disable-tests
make dist # Generates the tarball

sed \
    "s/@VERSION@/${VERSION}/g;s/@RELEASE@/${RELEASE}/g;s/@TARREDAS@/${TARNAME}/g" \
    < $SRCDIR/packaging/rpm/libcouchbase.spec.in > libcouchbase.spec

rpmbuild -bs --nodeps \
		 --define "_source_filedigest_algorithm md5" \
		 --define "_binary_filedigest_algorithm md5" \
		 --define "_topdir ${PWD}" \
		 --define "_sourcedir ${PWD}" \
		 --define "_srcrpmdir ${PWD}" libcouchbase.spec

SRCRPM=libcouchbase-${VERSION}-${RELEASE}*.src.rpm
RESDIR=$WORKSPACE/DIST
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
            --define "__lcb_is_cmake 1" \
            --rebuild \
            --resultdir="$CUR_RESDIR" $SRCRPM $@
    done
done
