#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Path;

GetOptions(
    'm|mirror=s' => \(my $MIRROR = "http://localhost:9999/ubuntu"),
    'i|install=s' => \(my $PACKAGES = ""),
    'U|update-only' => \(my $UPDATE_ONLY = 0),
    'R|root=s' => \(my $INST_ROOT = $ENV{PBROOT} || "/var/cache/pbuilder"),
    'D|dists=s' => \(my $DIST_LIST = "lucid,precise,trusty,wheezy"),
    'A|arches=s' => \(my $ARCHES = 'i386,amd64'),
    'h|help' => \(my $WANT_HELP = 0));

if ($WANT_HELP) {
    print <<EOF;

Usage: setup-cowbuilders.pl <OPTIONS>

 -m --mirror        Mirror to use for repository (default=$MIRROR)
 -i --install       Packages to install
 -U --update-only   Don't rebuild the image. Only install packages
 -h --help          This message
 -D --dists         Comma separated list of distributions
 -A --arches        Comma separated list of architectures
EOF
    exit(0);
}

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
    open my $fh, ">", "/tmp/instdeps.sh";
    my $pkglist_str = join(" ", @pkglist);
    print $fh "apt-get update && apt-get -y install $pkglist_str\n";
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
    if ($dist =~ m/wheezy/) {
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
    install_packages($dist, $arch, join(",",
            ("libevent-dev", "libev-dev", "libssl-dev", "autotools-dev", "unzip", "curl", "wget", $PACKAGES)));
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


