# Configuring

Note that you need to clone the submodule for this repository as well
which is required to parse and generate appropriate version numbers.

```
$ git submodule init
$ git submodule update
```

## Check your GPG Setup

You will need the GPG private key for the Couchbase builders in order to
sign the packages appropriately. If you do not have the GPG keys, you can set
the `NO_GPG` environment variable.


Additionally, for Debian repositories you will need the repository
key which is _different_ from the packaging key.



* The public _Packaging_ GPG ID is **`79CF7903`**
* The public _Repository_ GPG ID is .. TODO


# DEB (Debian, Ubuntu, etc.)

Building debian packages consists of setting up specialized chroot builders
via `cowbuilder`. `cowbuilder` itself is a wrapper around `pbuilder` and most
of the options it takes are passed directly to it.

## Prerequisites

```
apt-get install \
	build-essential \
	fakeroot \
	devscripts \
	dpkg-dev \
	gnupg \
	debhelper \
	cowbuilder \
	approx \
	ruby \
	rubygems \
	reprepro \
	createrepo \
	s3cmd
	
gem install rake
```

### Download ubuntu archive keyring

```
wget http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg
cp ubuntu-archive-keyring.gpg /usr/share/keyrings/
```

### Edit _Approx_

Edit `/etc/approx/approx.conf`

```
debian      http://ftp.debian.org/debian
ubuntu      http://ftp.ubuntu.com/ubuntu
```

Note that you can skip the _approx_ installation, but this will potentially
mean multiple un-necessary downloads as you configure your builders.


## Configuring Builders

You can then run the `deb/setup-cowbuilders.pl` script to set up your
builders. Configurable are the `-m` (mirror) options which let you
install things on your own.

If you wish to make testing this configuration a bit quicker, comment out
all but a single element of each of the `@ARCHES` and `@DISTS` arrays
towards the end of the file.

## Generating Packages

Generating the packages involves:

1. Generating the source tarball
1. Generating a proper Debian source archive (done in the host) from
   the tarball
1. Generating the binary packages (done in the builders)
1. Signing the binary packages (done in the host as well)


We'll assume you are located in the top-level directory
of the libcouchbase root, thus e.g.

```
$ git clone git://github.com/couchbase/libcouchbase
```

We'll also assume that this repository (_lcbpackage_) is a sibling
of the libcouchbase directory, thus

```
.
libcouchbase/
lcbpackage/
```


You will need a recent autotools to generate the initial tarball:

```
$ ./config/autorun.sh
$ ./configure --disable-plugins --disable-tests --disable-couchbasemock
```

Once this is done you can actually start invoking the builders:

```
$ ../lcbpackage/deb/build-deb-cowbuilders.sh
```

This will take quite some time to run as well.

The generated packages are located in the `DIST` directory which is
created in the current (i.e. top-level) directory. The provided repositories
will have been signed.

Once done, you can configure your builder as a 'master'.

## Configuring a Repository

TODO

RPM (CentOS, RHEL, SUSE, etc.)
==============================

Prerequisites
-------------


* Install mock

    yum install mock

* Add user to 'mock' group

    usermod -a -G mock [User name] && newgrp mock

* Setup configurations

    cp packaging/rpm/mock/* /etc/mock

* Initialize chroot.

    for CONFIG in centos-5-i386 centos-5-x86_64 centos-6-i386 centos-6-x86_64; do
        mock -r $CONFIG --init
    done

Build Packages
--------------

* Generate

    VERSION=$(git describe | awk -F- '{ print $1 }')
    RELEASE=$(git describe | awk -F- '{ print $2"_"$3 }')
    if [ "$RELEASE" = "_"]
    then
        RELEASE = 1;
        TARNAME="%{name}-%{version}"
    else
        TARNAME="%{name}-%{version}_%{release}"
    fi
    sed "s/@VERSION@/${VERSION}/g;s/@RELEASE@/${RELEASE}/g;s/@TARREDAS@/${TARNAME}/g" < packaging/rpm/libcouchbase.spec.in > libcouchbase.spec
    rpmbuild -bs --nodeps \
             --define "_source_filedigest_algorithm md5" \
             --define "_binary_filedigest_algorithm md5" \
             --define "_topdir ${PWD}" \
             --define "_sourcedir ${PWD}" \
             --define "_srcrpmdir ${PWD}" libcouchbase.spec

* Run the build

    for CONFIG in centos-5-i386 centos-5-x86_64 centos-6-i386 centos-6-x86_64; do
        mock -r $CONFIG --rebuild --resultdir=$HOME/input/$CONFIG libcouchbase-$VERSION-$RELEASE.src.rpm
    done