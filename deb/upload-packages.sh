#!/bin/sh

# Run from repository directory

set -x
set -e

RAKEFILE=$(dirname $0)/../rakefiles/repositories.rake
COMMON=$(dirname $0)/../common
TOPDIR=$PWD

. $COMMON/upload-vars.sh

for DIST in lucid oneiric precise; do
    cd DIST/$DIST
    rake -f $RAKEFILE builder:deb:upload:$DIST
done
