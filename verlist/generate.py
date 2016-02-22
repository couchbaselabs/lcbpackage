#!/usr/bin/env python

from jinja2 import Template
from argparse import ArgumentParser

ap = ArgumentParser()
ap.add_argument('-f', '--format', default='html', choices=('html', 'dita'))
ap.add_argument('-F', '--final-only', default=False, action='store_true',
        help="Only show the final version for each minor release")

options = ap.parse_args()
fname = 'template.html' if options.format == 'html' else 'template-dita.xml'
buf = open(fname, "r").read()

class VersionInfo(object):
    def __init__(self, verstr, name, is_final=False, is_current=False):
        self.verstr = verstr
        self.display = name
        self.is_final = is_final
        self.is_current = is_current

VERSIONS = [
        VersionInfo('lcb_207', '2.0.7', is_final=True),
        VersionInfo('lcb_210', '2.1.0'),
        VersionInfo('lcb_211', '2.1.1'),
        VersionInfo('lcb_212', '2.1.2'),
        VersionInfo('lcb_213', '2.1.3', is_final=True),
        VersionInfo('lcb_220', '2.2.0', is_final=True),
        VersionInfo('lcb_230', '2.3.0'),
        VersionInfo('lcb_231', '2.3.1'),
        VersionInfo('lcb_232', '2.3.2', is_final=True),
        VersionInfo('lcb_240', '2.4.0'),
        VersionInfo('lcb_241', '2.4.1'),
        VersionInfo('lcb_242', '2.4.2'),
        VersionInfo('lcb_243', '2.4.3'),
        VersionInfo('lcb_244', '2.4.4'),
        VersionInfo('lcb_245', '2.4.5'),
        VersionInfo('lcb_246', '2.4.6'),
        VersionInfo('lcb_247', '2.4.7'),
        VersionInfo('lcb_248', '2.4.8'),
        VersionInfo('lcb_249', '2.4.9', is_final=True),
        VersionInfo('lcb_250', '2.5.0'),
        VersionInfo('lcb_251', '2.5.1'),
        VersionInfo('lcb_252', '2.5.2'),
        VersionInfo('lcb_253', '2.5.3'),
        VersionInfo('lcb_254', '2.5.4'),
        VersionInfo('lcb_255', '2.5.5'),
        VersionInfo('lcb_256', '2.5.6', is_final=True, is_current=True)
]

if options.final_only:
    VERSIONS = [ x for x in VERSIONS if x.is_final ]

VERSIONS = list(reversed(VERSIONS))

def mk_hexvers(lcbvers):
    nums = "".join(["{0:02}".format(int(x)) for x in  lcbvers.split("-")[0].split(".")])
    verstr = int(nums, 16)
    return verstr


class UbuntuTarget(object):
    def __init__(self, version, display_version):
        self.version = version
        self.display_version = display_version

    def format_url(self, lcbvers, arch):
        return "libcouchbase-{0}_ubuntu{1}_{2}.tar".format(
                lcbvers, self.version, arch)

    def get_filename(self, lcbvers, arch):
        hv = mk_hexvers(lcbvers)
        if hv < 0x020302 and self.version == '1404':
            return "N/A";
        if hv < 0x020403 and self.version == 'wheezy':
            return "N/A"
        if hv >= 0x020404 and self.version == '1004':
            return "N/A"

        if arch == 'x86':
            arch = 'i386'
        else:
            arch = 'amd64'

        return self.format_url(lcbvers, arch)

class DebianTarget(UbuntuTarget):
    def format_url(self, lcbvers, arch):
        return "libcouchbase-{0}_{1}_{2}.tar".format(lcbvers, self.version, arch)

class WindowsTarget(object):
    def __init__(self, version, display_version):
        self.version = version
        self.display_version = display_version

    def get_filename(self, lcbvers, arch):
        if arch == 'x64':
            arch = 'amd64'
        return "libcouchbase-{0}_{1}_{2}.zip".format(lcbvers, arch, self.version)

class RedhatTarget(object):
    def __init__(self, version, display_version):
        self.version = version
        self.display_version = display_version

    def get_filename(self, lcbvers, arch):
        hv = mk_hexvers(lcbvers)
        if self.version.startswith('centos7') and hv < 0x020400:
            return "N/A"
        if self.version.startswith('centos5') and hv >= 0x020404:
            return 'N/A'

        if arch == 'x86':
            if self.version.startswith('centos7'):
                return 'N/A' # No 32 bit builds for EL7

            if self.version.startswith('centos5'):
                arch = 'i386'
            else:
                arch = 'i686'
        else:
            arch = 'x86_64'
        return "libcouchbase-{0}_{1}_{2}.tar".format(lcbvers, self.version, arch)

class SourceTarget(object):
    def __init__(self):
        self.display_version = "Source Archive"

    def get_filename(self, lcbvers, arch):
        lcbvers = lcbvers.replace("-", "_")
        return "libcouchbase-{0}.tar.gz".format(lcbvers)

TARGETS = (
        UbuntuTarget('1004', 'Ubuntu 10.04'),
        UbuntuTarget('1204', 'Ubuntu 12.04'),
        UbuntuTarget('1404', 'Ubuntu 14.04'),
        DebianTarget('wheezy', 'Debian Wheezy'),
        RedhatTarget('centos55', 'Enterprise Linux 5'),
        RedhatTarget('centos62', 'Enterprise Linux 6'),
        RedhatTarget('centos7', 'Enterprise Linux 7'),
        WindowsTarget('vc9', 'Visual Studio 2008'),
        WindowsTarget('vc10', 'Visual Studio 2010'),
        WindowsTarget('vc11', 'Visual Studio 2012'),
    )

tmpl = Template(buf, trim_blocks=True, lstrip_blocks=True)
print tmpl.render(versions=VERSIONS, targets=TARGETS, tarball=SourceTarget())
