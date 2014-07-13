# The local directory to server as the repository root
export LCB_REPO_PREFIX=$HOME/repos/

# This indicates the master is local, not remote
export MASTER_IS_LOCAL=1

# GPG key for the _repository_
export APT_GPG_KEY=D9223EDA

# GPG Key for dpkg/debsign
export DPKG_GPG_KEY=79CF7903

# Architectures for debian
export DEB_ARCHES="amd64 i386"
export QUICK_DEB_ARCHES="amd64"

export DEB_DISTROS="lucid precise trusty"
export QUICK_DEB_DISTROS=lucid

export RPM_ARCHES="x86_64 i386"
export RPM_RELNOS="5 6 7"
export QUICK_RPM_ARCHES=x86_64
export QUICK_RPM_RELNOS=6

export RPM_GPG_KEY=CD406E62
mkdir -p $LCB_REPO_PREFIX
