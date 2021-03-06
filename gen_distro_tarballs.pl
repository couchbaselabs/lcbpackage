#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Path qw(rmtree mkpath);
use File::Copy;
use File::Basename;
use Cwd qw(getcwd);

GetOptions(
    'V|version=s' => \my $VERSION,
    'R|rpm=s' => \(my $RPMDIR = ""),
    'D|deb=s' => \(my $DEBDIR = "")
);

if (!$VERSION) {
    die("Version must be specified");
}

# Architectures
my @ARCHES = (qw(x86 x64));
my %RPMSPECS = (
    '62' => {
        suffix => 'rpm',
        dist => 'centos62',
        search_path => "$RPMDIR/6.2",
        arch_tar => sub {
            my $name = shift;
            return $name eq 'x86' ? 'i686' : 'x86_64';
        },
        arch_pkg => sub {
            my $name = shift;
            return $name eq 'x86' ? 'i686' : 'x86_64';
        },
    },
    '7' => {
        suffix => 'rpm',
        dist => 'centos7',
        search_path => "$RPMDIR/7",
        arch_tar => sub { 'x86_64' },
        arch_pkg => sub { 'x86_64' }
    }
);

sub convert_deb_arch {
    my $name = shift;
    return $name eq 'x86' ? 'i386' : 'amd64';
}

my %DEBSPECS = (
    trusty => {
        dist => 'ubuntu1404',
    },
    'jessie' => {
        dist => 'jessie'
    },
    'xenial' => {
        dist => 'ubuntu1604'
    },
    'bionic' => {
        dist => 'ubuntu1804'
    },
    'stretch' => {
        dist => 'stretch'
    }
);

while (my ($k,$v) = each %DEBSPECS) {
    $v->{search_path} = "$DEBDIR/pool/$k";
    $v->{suffix} = "deb";
    $v->{arch_pkg} = \&convert_deb_arch;
    $v->{arch_tar} = \&convert_deb_arch;
}

# Find the packages
my @SPECS;
if ($RPMDIR) {
    push @SPECS, values %RPMSPECS;
}
if ($DEBDIR) {
    push @SPECS, values %DEBSPECS;
}


my $TMP_PREFIX = "pkgtmp";
my $OUT_DIR = "tarballs";

mkpath($OUT_DIR);

foreach my $spec (@SPECS) {
    # Generate the output name
    foreach my $arch (@ARCHES) {
        if ($arch eq 'x86' && $spec->{suffix} eq 'rpm' && $spec->{dist} eq 'centos7') {
            next;
        }
        my $output_name = sprintf("libcouchbase-%s_%s_%s",
            $VERSION, $spec->{dist}, $spec->{arch_tar}->($arch));
        print "Output Name: $output_name\n";
        my $tarname = "$output_name.tar";
        my $tmpdir = "$TMP_PREFIX/$output_name";

        if (-d $tmpdir) {
            rmtree($tmpdir);
        }

        mkpath($tmpdir);

        my $findcmd = sprintf("find %s -iname '*%s*.%s'",
            $spec->{search_path}, $spec->{arch_pkg}->($arch), $spec->{suffix});
        print "$findcmd\n";
        my @pkgs = split('\n', qx($findcmd));
        foreach my $found (@pkgs) {
            print "Found $found\n";
            my $dest = basename($found);
            copy($found, "$tmpdir/$dest");
        }

        system("tar cf $OUT_DIR/$tarname -C $TMP_PREFIX $output_name");
    }
}
