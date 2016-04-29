#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Path;

my @DEFAULT_PACKAGES = ('libevent-dev', 'libev-dev', 'libssl-dev', 'unzip', 'curl', 'wget', 'debhelper', 'cmake');

GetOptions(
    'm|mirror=s' => \(my $MIRROR = "http://localhost:9999/ubuntu"),
    'i|install=s' => \(my $PACKAGES = join(',', @DEFAULT_PACKAGES)),
    'U|update-only' => \(my $UPDATE_ONLY = 0),
    'R|root=s' => \(my $INST_ROOT = $ENV{PBROOT} || "/var/cache/pbuilder"),
    'D|dists=s' => \(my $DIST_LIST = "precise,trusty,wheezy,xenial,jessie"),
    'A|arches=s' => \(my $ARCHES = 'i386,amd64'),
    'h|help' => \(my $WANT_HELP = 0),
    'x|execute=s' => \(my $EXECSTR = ''));

if ($WANT_HELP) {
    print <<EOF;

Usage: setup-cowbuilders.pl <OPTIONS>

 -m --mirror        Mirror to use for repository (default=$MIRROR)
 -i --install       Packages to install
 -U --update-only   Don't rebuild the image. Only install packages
 -h --help          This message
 -D --dists         Comma separated list of distributions
 -A --arches        Comma separated list of architectures
 -x --execute       Execute STRING inside of environment
EOF
    exit(0);
}

# GPG Key hash for CMake (ppa:mnunberg/cmake)
my $CM_KEYHASH = '2BF52A95';
my $CM_PPA = "http://ppa.launchpad.net/mnunberg/cmake/ubuntu";


sub run_command {
    my $cmdstr = join(' ', @_);
    print STDERR "Executing $cmdstr\n";
    my $rv = system(@_);
    if ($rv) {
        die("Command $cmdstr failed with code $rv");
    }
}

sub gen_basepath {
    my ($dist,$arch) = @_;
    return "$INST_ROOT/$dist-$arch.cow";
}

sub install_packages {
    my ($dist, $arch, $packages) = @_;
    my @pkglist = split(/,/, $packages);
    my $pkglist_str = join(" ", @pkglist);
    open my $fh, ">", "/tmp/instdeps.sh";
    print $fh "set -x\n";
    print $fh "set -e\n";

    if ($EXECSTR) {
        print $fh $EXECSTR . "\n";
    } else {
        # Needed for CMake PPA repository
        if ($dist eq 'precise') {
            print $fh 'FNAMES=$(ls /etc/apt/sources.list.d | grep cmake) || true'."\n";
            print $fh 'if [ -z "$FNAMES" ]; then'."\n";
            print $fh "echo deb $CM_PPA $dist main > /etc/apt/sources.list.d/mnunberg-cmake-$dist.list\n";
            print $fh 'fi'."\n";
            # Import key
            print $fh "(apt-key list | grep -q $CM_KEYHASH) || apt-key adv --keyserver keyserver.ubuntu.com --recv-key $CM_KEYHASH\n";
        }

        print $fh "apt-get update\n";
        print $fh "apt-get -y install $pkglist_str\n";
    }

    close($fh);

    my @cmd = (
        "sudo", "cowbuilder",
        "--execute", "--save",
        "--basepath", gen_basepath($dist, $arch),
        "--", "/tmp/instdeps.sh");

    run_command(@cmd);
}


sub setup_image {
    my ($dist,$arch) = @_;
    my $keyring = "/usr/share/keyrings/ubuntu-archive-keyring.gpg";
    my $mirror = $MIRROR;
    my $distlist = "main universe";
    if ($dist =~ m/wheezy|jessie/) {
        #debian
        $keyring =~ s/ubuntu/debian/g;
        $mirror =~ s/ubuntu/debian/g;
        $distlist = "main";
    }
    my @cmd = (
        "sudo", "cowbuilder",
        "--create",
        "--distribution", $dist,
        "--components", $distlist,
        "--basepath", gen_basepath($dist, $arch),
        "--mirror", $mirror,

        "--debootstrapopts",
        "--arch=$arch",
        "--debootstrapopts",
        "--keyring=$keyring");

    run_command(@cmd);
    install_packages($dist, $arch, join(",", @DEFAULT_PACKAGES, $PACKAGES));
}

my @arches = split(',', $ARCHES);
my @dists = split(',', $DIST_LIST);

foreach my $dist (@dists) {
    foreach my $arch (@arches) {
        if ($UPDATE_ONLY) {
            install_packages($dist, $arch, $PACKAGES);
        } else {
            setup_image($dist, $arch);
        }
    }
}


