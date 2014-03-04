# Run from the source root!
set -x
set -e

PARSE_SCRIPT=$(dirname $0)/../git-describe-parse/parse-git-describe.pl

make dist
VERSION=$($PARSE_SCRIPT --tar)
DEB_VERSION=$($PARSE_SCRIPT --deb)
WORKSPACE=$PWD/build
PKGDIR=$WORKSPACE/libcouchbase-$VERSION
GPG_KEY=79CF7903

mkdir -p $PKGDIR
cp -r packaging/deb $PKGDIR/debian
cp libcouchbase-$VERSION.tar.gz $WORKSPACE/libcouchbase_$DEB_VERSION.orig.tar.gz
(
cd $WORKSPACE;
tar zxf libcouchbase_$DEB_VERSION.orig.tar.gz
)
(
cd $PKGDIR;
dch --no-auto-nmu --newversion "$DEB_VERSION" "Release package for libcouchbase $DEB_VERSION"
debian/rules clean
dpkg-source -b .
)
mv $WORKSPACE/*.{dsc,tar.gz} $PWD
rm -rf $WORKSPACE
if [ -z "${NO_GPG}" ]
then
    export DEB_FLAGS="$DEB_FLAGS -sa -k$GPG_KEY"
fi

for DIST in lucid oneiric precise; do
    for ARCH in i386 amd64; do
        RESDIR=DIST/$DIST
        [ -d $RESDIR ] || mkdir -p $RESDIR
        sudo cowbuilder \
            --build \
            --basepath /var/cache/pbuilder/$DIST-$ARCH.cow \
            --buildresult $RESDIR \
            --debbuildopts -j20 \
            libcouchbase_$DEB_VERSION.dsc
    done
done
