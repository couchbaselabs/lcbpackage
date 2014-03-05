# The local directory to server as the repository root
export LCB_REPO_PREFIX=/repos/

# This indicates the master is local, not remote
export MASTER_IS_LOCAL=1

# GPG key for the _repository_
export APT_GPG_KEY=D9223EDA

# GPG Key for dpkg/debsign
export DPKG_GPG_KEY=79CF7903

# Architectures for debian
export DEB_ARCHES="amd64 i386"
export QUICK_DEB_ARCHES="amd64"

export DEB_DISTROS="lucid oneiric precise"
export QUICK_DEB_DISTROS=lucid

export RPM_GPG_KEY=$GPG_KEY
mkdir -p $LCB_REPO_PREFIX
