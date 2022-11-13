#!/bin/bash
set -x

# build drbd-9 package
cd ~/Archive/drbd
make tarball
make kmp-rpm

# build drbd-utils package
cd ~/Archive/drbd-utils
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
UTIL_VERSION=$(sed -n -e "s/^PACKAGE_VERSION='\(.*\)'/\1/p" configure)
make tarball VERSION=${UTIL_VERSION}
cp drbd-utils-${UTIL_VERSION}.tar.gz  ~/rpmbuild/SOURCES
./configure --enable-spec
# remive trailing comment like %endif # with xxx for imcompatible new rpmbuild
sed -i -e 's/^%endif.\+/%endif/' drbd.spec
rpmbuild -bb --without sbinsymlinks --without heartbeat --without 83support --without 84support drbd.spec


