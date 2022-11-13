#!/bin/bash
set -x
# build drbd-9 package
cd ~/Archive/drbd-9.0
make tarball
make kmp-rpm
# build drbd-utils package
cd ~/Archive/drbd-utils
# patch -p 0 << '__EOF'
# --- drbd.spec.in	2022-11-10 11:08:26.166466000 +0000
# +++ drbd.spec.in.new	2022-11-10 11:21:15.661703000 +0000
# @@ -460,9 +460,11 @@
#  %endif # with manual
 
#  %prep
# -%setup -q -n drbd-utils-%{upstream_version}
# -
# +#%setup -q -n drbd-utils-%{upstream_version}
# +git clone --recursive -b v${VERSION} https://github.com/LINBIT/drbd-utils.git drbd-utils-${VERSION}
# +cd drbd-utils-${VERSION}
#  %build
# +cd drbd-utils-${VERSION}
#  # rebuild configure...
#  aclocal
#  autoheader
# @@ -488,6 +490,7 @@
#  %endif
 
#  %install
# +cd drbd-utils-${VERSION}
#  rm -rf %{buildroot}
#  make install DESTDIR=%{buildroot} CREATE_MAN_LINK=no

# __EOF
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
UTIL_VERSION=$(sed -n -e "s/^PACKAGE_VERSION='\(.*\)'/\1/p" configure)
make tarball VERSION=${UTIL_VERSION}
cp drbd-utils-${UTIL_VERSION}.tar.gz  ~/rpmbuild/SOURCES
./configure --enable-spec
sed -i -e 's/^%endif.\+/%endif/' drbd.spec
# make .filelist
# make drbd.spec
# make rpmprep
# rpmbuild -bb --without 83support --without 84support --without manual drbd.spec
rpmbuild -bb --without sbinsymlinks --without heartbeat --without 83support --without 84support drbd.spec


