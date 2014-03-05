#!/bin/sh
# vim: softtabstop=4 ts=4 shiftwidth=4 expandtab autoindent
set -x
set -e

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

PARSE_SCRIPT=$SCRIPTPATH/../git-describe-parse/parse-git-describe.pl
. $SCRIPTPATH/../common/vars.sh

TARNAME=libcouchbase-$( $PARSE_SCRIPT --tar)
VERSION=$( $PARSE_SCRIPT --rpm-ver)
RELEASE=$( $PARSE_SCRIPT --rpm-rel)

sed \
    "s/@VERSION@/${VERSION}/g;s/@RELEASE@/${RELEASE}/g;s/@TARREDAS@/${TARNAME}/g" \
    < packaging/rpm/libcouchbase.spec.in > libcouchbase.spec

rpmbuild -bs --nodeps \
		 --define "_source_filedigest_algorithm md5" \
		 --define "_binary_filedigest_algorithm md5" \
		 --define "_topdir ${PWD}" \
		 --define "_sourcedir ${PWD}" \
		 --define "_srcrpmdir ${PWD}" libcouchbase.spec

