# The local directory to server as the repository root

if [ -z "$LCB_REPO_PREFIX" ]; then
    LCB_REPO_PREFIX=$HOME/repos/
fi
export LCB_REPO_PREFIX

# This indicates the master is local, not remote
export MASTER_IS_LOCAL=1

# GPG key for the _repository_
export APT_GPG_KEY=D9223EDA

# GPG Key for dpkg/debsign
export DPKG_GPG_KEY=D9223EDA

# Architectures for debian
if [ -z "$DEB_ARCHES" ]; then
    DEB_ARCHES="amd64 i386"
fi
export DEB_ARCHES

if [ -z "$DEB_DISTROS" ]; then
    DEB_DISTROS="trusty wheezy xenial jessie bionic stretch"
fi
export DEB_DISTROS

# RPM
if [ -z "$RPM_ARCHES" ]; then
    RPM_ARCHES="x86_64 i386"
fi
export RPM_ARCHES

if [ -z "$RPM_RELNOS" ]; then
    RPM_RELNOS="6 7"
fi
export RPM_RELNOS

export RPM_GPG_KEY=CD406E62
mkdir -p $LCB_REPO_PREFIX
