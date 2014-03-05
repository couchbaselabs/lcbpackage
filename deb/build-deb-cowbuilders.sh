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

. $SRCIPTPATH/../common/vars.sh

make dist
VERSION=$($PARSE_SCRIPT --tar)
DEB_VERSION=$($PARSE_SCRIPT --deb)
WORKSPACE=$PWD/build
PKGDIR=$WORKSPACE/libcouchbase-$VERSION

mkdir -p $PKGDIR
cp -r packaging/deb $PKGDIR/debian
cp libcouchbase-$VERSION.tar.gz $WORKSPACE/libcouchbase_$DEB_VERSION.orig.tar.gz

# Extract the package
(
    cd $WORKSPACE;
    tar zxf libcouchbase_$DEB_VERSION.orig.tar.gz
)

# Sign the source package
if [ -z "${NO_GPG}" ]
then
    PKG_GPG_OPTS="--debbuildopts -k$DPKG_GPG_KEY"
    SRC_GPG_OPTS="-k $DPKG_GPG_KEY"
fi

# Generate the debianized source
(
    cd $PKGDIR;
    dch \
        --no-auto-nmu \
        --newversion "$DEB_VERSION" \
        "Release package for libcouchbase $DEB_VERSION"
    
    dpkg-buildpackage -rfakeroot -d -S -sa -k$DPKG_GPG_KEY
)


mv $WORKSPACE/*.{dsc,tar.gz} $PWD
rm -rf $WORKSPACE

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
            --basepath /var/cache/pbuilder/$DIST-$ARCH.cow \
            --buildresult $RESDIR \
            --debbuildopts -j20 \
            --debbuildopts "-us -uc" \
            libcouchbase_$DEB_VERSION.dsc
        if [ -z "$NO_GPG" ]
        then debsign -k $DPKG_GPG_KEY --no-re-sign \
            $RESDIR/*$ARCH*.changes $RESDIR/*.dsc
        fi
    done
done
