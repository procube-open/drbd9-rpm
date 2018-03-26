#!/bin/bash
set -x
# build drbd-9 package
cd ~/Archive/drbd-9.0
git checkout drbd-9.0.12
make .filelist
make kmp-rpm
# build drbd-utils package
cd ~/Archive/drbd-utils
git checkout v9.3.0
patch -p 0 << __EOF
--- ../drbd-utils.orig/drbd.spec.in     2017-09-01 15:01:35.721074085 +0900
+++ ./drbd.spec.in      2017-09-04 10:48:54.719119053 +0900
@@ -31,6 +31,7 @@
 # conditionals may not contain "-" nor "_", hence "bashcompletion"
 %bcond_without bashcompletion
 %bcond_without sbinsymlinks
+%undefine with_sbinsymlinks
 # --with xen is ignored on any non-x86 architecture
 %bcond_without xen
 %bcond_without 83support
rpmbuild -bb rpmbuild/SPECS/shibboleth.spec -with fastcgi
cp /tmp/rpms/* rpmbuild/RPMS/x86_64
__EOF
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --without-83support --without-84support
make .filelist
make rpm
# build drbdmanage package
cd ~/Archive/drbdmanage
git checkout v0.99.16
make rpm
cp dist/*.rpm ~/rpmbuild/RPMS/noarch
