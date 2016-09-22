<!--- vim: set noexpandtab: -->

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
* The public _Repository_ GPG ID is **`D9223EDA`**
* The public _RPM_ GPG ID is **`CD406E62`**


# DEB (Debian, Ubuntu, etc.)

Building debian packages consists of setting up specialized chroot builders
via `cowbuilder`. `cowbuilder` itself is a wrapper around `pbuilder` and most
of the options it takes are passed directly to it.

## Prerequisites

Note that there is a bug in pbuilder (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=627086)
which is only fixed in Ubuntu 12.04 (or debian equivalent). As such it is
recommended to not use an older version.


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
	reprepro \
	createrepo \
	cmake
```

I

### Note for Ubuntu Precise

It is highly recommended you use a newer Ubuntu/Debian release (Wheezy or Trusty).
Precise is also supported, however the CMake version must be upgraded to be
2.8.9 at least. You may obtain this version by adding my PPA here:
https://launchpad.net/~mnunberg/+archive/ubuntu/cmake


For testing the repository layout itself you will also need a 
webserver.

### Download achive keyrings

If installing Ubuntu systems a Debian master, you will need the Ubuntu keyring,
which can be obtained using the following command.

```
wget http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg
cp ubuntu-archive-keyring.gpg /usr/share/keyrings/
```

Conversely, if you are building a debian host on an Ubuntu master, install the
`debian-keyring` and `debian-archive-keyring` packages.

### Edit _Approx_

Edit `/etc/approx/approx.conf`

```
debian      http://ftp.debian.org/debian
ubuntu      http://ftp.ubuntu.com/ubuntu
```

Note that you can skip the _approx_ installation, but this will potentially
mean multiple un-necessary downloads as you configure your builders.

If you _do_ choose to skip _approx_ then you will need to specify a mirror
in the script (later on), as the script will by default look for a repository
on `localhost:9999` (default approx listening port).

## Configuring Builders

You can then run the `deb/setup-cowbuilders.pl` script to set up your
builders. Configurable are the `-m` (mirror) options which let you
install things on your own.

If you wish to make testing this configuration a bit quicker, comment out
all but a single element of each of the `@ARCHES` and `@DISTS` arrays
towards the end of the file.

### Common Issues

You might run into some issues when generating the packages:

#### Cannot verify keyring

This is because your packages are signed with a GPG key which is not imported
into your keyring. If you have properly installed all the keyring as mentioned
above, it may be because of a stale package configuration (or a stale approx proxy).
In this case, run `apt get update` _and_ delete your `approx` cache files, usually
found in `/var/cache/approx`.

#### `file exists`
You will get this error if you try to re-configure a builder that already exits,
using the `setup-cowbuilders.pl` script. If the host is indeed already configured
(and you just want to verify/update the installation), ensure you pass the `-U`
option to `setup-cowbuilders.pl`. If the host is partially configured, ensure you
delete the directory (e.g. `/var/lib/pbuilder/i386-wheezy.cow`) and retry.

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


```
$ ../lcbpackage/deb/build-deb-cowbuilders.sh
```

This will take quite some time to run as well.

The generated packages are located in the `LCBPACKAGE-DEB/DIST` directory which is
created in the current (i.e. top-level) directory. The provided repositories
will have been signed.

Once done, you can configure your builder as a 'master'.

## Configuring a Repository

Creating the repository allows you to create a and use this layout as
a source for `apt-get` and friends. The steps involve:

1. Selecting a directory to act as the repository root
2. Creating the repository structure within that directory
3. Signing the repository metadata
4. Copying the built packages into the repository
5. Configuring a webserver to serve from the repository

### Create Directory Structure

The default configuration for repositories may be found inside
the `common/vars.sh`. By default the repository structure is created
inside a directory named `/repo` (i.e. relative to the current `$HOME`).
This would assume running as the root user. You may choose to use a
different directory if you do not wish to run as root.

The following script (run from within the `libcouchbase` directory) will
set up a repository structure. It will also wipe any existing contents
of the repository itself, so be careful with it.

It may be recommended to run this as a different user eventually..

```
$ ../lcbpackage/deb/mk-localrepo.sh
```


### Configuring Apache

Once you have the structure set up, configure the webserver. On Debian this is
done via apache. We'll use a simple setup and ignore security as this is a local
setup anyway:

```
$ vim /etc/apache2/sites-enabled/000-default
```

Change the `DocumentRoot` to `/root/repos`; also change the
`<Directory>` directive to use `/root/repos` instead of `/var/www`.

Also ensure your `$HOME` is traversable:

```
$ chmod a+x $HOME
```

Now, reload your webserver

```
$ service apache2 reload
```

### Testing the Repository

First verify you are able to see the contents of the repository with a tool like
curl (or your web browser).

Once done, follow the instructions on http://www.couchbase.com/communities/c-client-library.

#### Common Steps

Before running any of the tests, ensure any references of libcouchbase are not
present:

```
$ dpkg -P 'libcouchbase*'
```

which will completely unconfigure and remove any prior installs

#### Testing fresh installs

Uncomment the `packages.couchbase.com` URL in the `couchbase.list` file downloaded
above; copy the line, and replace the URL with localhost.

Then

```
$ apt-get update
$ apt-get install libcouchbase2 libcouchbase2-libevent libcouchbase-dev libcouchbase2-bin
```

Check `cbc` reports proper version

```
$ cbc version
```

Then verify the development headers are sound as well, by compiling an SDK
against it. Typically I use Python

```
$ apt-get install python-dev
$ git clone git://github.com/couchbase/couchbase-python-client.git
$ cd couchbase-python-client
$ python setup.py build_ext
```

#### Testing upgrades

Uncomment the original entry in `couchbase.list` to restore the current upstream
repository. Then

```
$ apt-get update
$ apt-get install libcouchbase2 libcouchbase2-libevent libcouchbase-dev libcouchbase2-bin
```

Verify that the older version is actually being used:

```
$ cbc version
```

Now perform the same steps as in the "Fresh Install" section. The result should
be identical.



# RPM (CentOS, RHEL, SUSE, etc.)

## Prerequisites

### Packages

```
# For EL7
yum -y install \
    sudo git \
    gcc gcc-c++ \
    make cmake \
    rpm-sign \
    rpm-build \
    rpm-devel \
    createrepo \
    expect 
```

### Mock

In RPM-land, the building itself is performed via the `mock` tool which
sets up a bunch of chroots and invokes the builds inside those 
directories.

Most of the routine commands do not need root access

Install the mock:

```
sudo yum install mock
```

Add your user to the `mock` group

```
sudo usermod -a -G mock $(whoami)
```

Initiate a new shell with the group applied (or just exit and log
back in)

```
newgrp mock
```

The mock needs to operate on a bunch of configuration files.
You need to place these files in `/etc/mock`. The files themselves
are located in the `rpm/mock` directory within the repository:

```
sudo cp rpm/mock/* /etc/mock
```

Once you have copied all the configuration files, you can initialize
the base chroots for each environment. This may take some time

```
./rpm/init-mocks.sh --init
```

## Building Packages

The process of building packages consists of:

1. Generating a `.spec` and `.src.rpm` file
2. Telling `mock` about those files and building them

These are handled in a single script via the `rpm/build-rpms.sh`

The following commands should be executed from the `libcouchbase`
repository. We assume the `lcbpackage` repository is a sibling of
the `libcouchbase` repository.

```
../lcbpackage/rpm/build-rpms.sh
```

You may optionally pass the `--verbose` option to the script, which will show you what is
going on.

Unfortunately, it seems that Yum likes to take its sweet time downloading packages,
however it does not display the traditional progress bar. This is likely due to how
mock captures the builder output. In any event, do not be alarmed if your build
seems to "hang". Inspect network and disk utilization if you suspect something else
may be amiss.

The output packages will be in the `LCBPACKAGE-RPM` directory. This directory is
created anew each time the build script is run (so make sure you save any contents
of that directory if you need to rebuild)

## Generating a Repository

```
../lcbpackage/rpm/mk-localrepo.sh
```

Which will place the resulting files inside the `LCB_REPO_PREFIX` path
as determined by the setting in `common/vars.sh`


Once this is done you will want to install apache.

### Configuring Apache

```
$ sudo yum -y install httpd
$ sudo service httpd start
```

Now configure apache to allow for a user directory. This disabled by default.

Edit the `/etc/httpd/conf/httpd.conf` file. Search for the `UserDir` directive.
It should look like:

```
 # UserDir public_html
```

and uncomment this line.

Now you should also enable symlinks as we will symlink the `repos` directory
to `public_html` (later).

Create this section in `httpd.conf`

```
<Directory /home/*/public_html>
	AllowOverride Indexes
	Options Indexes SymLinksIfOwnerMatch
</Directory>
```

Now that you are done, reload apache

```
$ sudo service httpd reload
```

Go back to your home directory:

```
$ ln -s repos public_html
```

**Make sure `selinux` is disabled or you will get odd errors**.
To check if it's enabled
```
$ selinuxenabled && echo "Have selinux on"
```

If it _is_ enabled, modify `/etc/selinux/config`. Ensure that
`SELINUX=disabled` rather than `enforcing` or `permissive`.
If you needed to make modifications to the host then reboot it. Selinux will
not be disabled until the machine has been rebooted.

To verify that this all works, navigate to `http://${host}/~${user}` and you
should see a top-level `rpm` directory. Replace `${host}` with the visible
IP accessible to your HTTP client and `${user}` with the user that you are
building with.

### Testing Installs

To test installs, first download the template `couchbase.repo` file
following the _Getting Started_ guide on the "C Community" portal:
http://www.couchbase.com/communities/c-client-library

```
$ sudo wget -O \
	/etc/yum.repos.d/couchbase.repo \
	http://packages.couchbase.com/rpm/couchbase-centos62-x86_64.repo
```

Copy this file like so:

```
$ sudo cp /etc/yum.repos.d/couchbase.repo /etc/yum.repos.d/couchbase-local.repo
```


Then edit the `couchbase-local` repo. The line saying `[couchbase]`
should be modified to `[couchbase-local]`.

Before proceeding, remove any existing installs.

```
$ sudo yum remove 'libcouchbase*'
```

To test a fresh install, disable the old upstream repo:

```
$ sudo yum --disablerepo couchbase install \
	libcouchbase2 libcouchbase2-libevent libcouchbase2-bin libcouchbase-devel
```

Run `cbc` to see if we have the right version installed

```
$ cbc version
```

Now try to compile an SDK:

```
$ git clone git://github.com/couchbase/couchbase-python-client.git
$ cd couchbase-python-client
$ python setup.py build_ext
```

To test an upgrade, first remove any existing installations, as above.

Then install from the upstream:

```
$ sudo yum --disablerepo couchbase-local install \
	libcouchbase2 libcouchbase2-libevent libcouchbase2-bin libcouchbase-devel
```

Again, verify the correct version with `cbc`

```
$ cbc version
```
