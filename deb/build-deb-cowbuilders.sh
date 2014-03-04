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

if [ -z "${NO_GPG}" ]
then
    PKG_GPG_OPTS="--debbuildopts -k$GPG_KEY"
    SRC_GPG_OPTS="-k $GPG_KEY"
fi
(
    cd $PKGDIR;
    dch \
        --no-auto-nmu \
        --newversion "$DEB_VERSION" \
        "Release package for libcouchbase $DEB_VERSION"
    
    dpkg-buildpackage -rfakeroot -d -S -sa -k$GPG_KEY
)

mv $WORKSPACE/*.{dsc,tar.gz} $PWD
rm -rf $WORKSPACE

for DIST in lucid oneiric precise; do
    for ARCH in i386 amd64; do
        RESDIR=DIST/$DIST
        [ -d $RESDIR ] || mkdir -p $RESDIR
        sudo cowbuilder \
            --build \
            --basepath /var/cache/pbuilder/$DIST-$ARCH.cow \
            --buildresult $RESDIR \
            --debbuildopts -j20 \
            --debbuildopts -sa \
            $PKG_GPG_OPTS \
            libcouchbase_$DEB_VERSION.dsc
    done
done
