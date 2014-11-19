# Run from the source root!
set -x
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

PARSE_SCRIPT=$SCRIPTPATH/../git-describe-parse/parse-git-describe.pl
if [ $(echo "$@" | grep -q quick) ]
then
    QUICK=1
fi

. $SCRIPTPATH/../common/vars.sh

SRCDIR=$PWD
VERSION=$($PARSE_SCRIPT --tar)
DEB_VERSION=$($PARSE_SCRIPT --deb)

TARNAME_BASE=libcouchbase-$VERSION
DEBSRC_NAME=libcouchbase_$DEB_VERSION.orig.tar.gz
WORKSPACE=$SRCDIR/LCBPACKAGE-DEB

# Sign the source package
if [ -z "${NO_GPG}" ]
then
    PKG_GPG_OPTS="--debbuildopts -k$DPKG_GPG_KEY"
    SRC_GPG_OPTS="-k $DPKG_GPG_KEY"
fi

# Configure the sources
rm      -rf $WORKSPACE
mkdir   -p  $WORKSPACE
cd          $WORKSPACE

cmake       $SRCDIR --disable-plugins --disable-tests
make dist

EXTRACTED=$WORKSPACE/$TARNAME_BASE

# Rename the tarball to its debianized version
ln -s $WORKSPACE/$TARNAME_BASE.tar.gz $WORKSPACE/$DEBSRC_NAME
tar -xf $TARNAME_BASE.tar.gz
cp -a $SRCDIR/packaging/deb $EXTRACTED/debian

( \
    cd $EXTRACTED && \
    dch --no-auto-nmu \
    --package libcouchbase \
    --newversion "$DEB_VERSION" \
    --create \
    "Release package for libcouchbase $DEB_VERSION" \
    && \
    dpkg-buildpackage -rfakeroot -d -S -sa -k$DPKG_GPG_KEY \
)


# mv $WORKSPACE/*.{dsc,tar.gz} $PWD
if [ -z "$PBROOT" ]; then
    PBROOT=/var/cache/pbuilder
fi

if [ -n "$QUICK" ]
then
    DISTS=$QUICK_DEB_DISTROS
    ARCHES=$QUICK_DEB_ARCHES
else
    DISTS=$DEB_DISTROS
    ARCHES=$DEB_ARCHES
fi

for DIST in $DISTS; do
    for ARCH in $ARCHES; do
        RESDIR=DIST/$DIST
        [ -d $RESDIR ] || mkdir -p $RESDIR
        sudo cowbuilder \
            --build \
            --basepath $PBROOT/$DIST-$ARCH.cow \
            --buildresult $RESDIR \
            --debbuildopts -j20 \
            --debbuildopts "-us -uc -R'make -f debian/rules LCB_BUILDING_WITH_CMAKE=1'" \
            libcouchbase_$DEB_VERSION.dsc
        if [ -z "$NO_GPG" ]
        then debsign -k $DPKG_GPG_KEY --no-re-sign \
            $RESDIR/*$ARCH*.changes $RESDIR/*.dsc
        fi
    done
done
