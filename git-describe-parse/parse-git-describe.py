#!/usr/bin/env python
from optparse import OptionParser
from subprocess import Popen, PIPE


op = OptionParser()
op.add_option('--basetag',
              help="Print base tag", action='store_true')
op.add_option('--ncommits',
              help="Print number of commits since tag",
              action='store_true')
op.add_option('--abbrev-sha',
              help="Print abbreviated SHA1",
              action='store_true')
op.add_option('--always-print-extra',
              help="Always print abbrev/ncommits, even if HEAD==tag",
              action='store_true')

options, args = op.parse_args()
stdout, stderr = Popen(['git', 'describe', '--long'], stdout=PIPE).communicate()
components = stdout.strip().split('-')
sha = components.pop()
ncommits = components.pop()
version = "-".join(components)

print_extras = (int(ncommits)) or options.always_print_extra

if options.basetag:
    print version
if options.ncommits and print_extras:
    print ncommits
if options.abbrev_sha and print_extras:
    print sha
