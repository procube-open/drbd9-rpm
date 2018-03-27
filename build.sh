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
patch -R -p 1 << '__EOF'
--- new/Makefile.in	2018-03-27 02:50:49.237740424 +0900
+++ old/Makefile.in	2018-03-26 21:58:45.000000000 +0900
@@ -89,10 +89,6 @@
 	$(MAKE) -C documentation/ja/v84 doc
 endif
 
-.PHONY: drbdsetup
-drbdsetup:
-	$(MAKE) -C user/v9 drbdsetup
-
 # we cannot use 'git submodule foreach':
 # foreach only works if submodule already checked out
 .PHONY: check-submods
@@ -212,7 +208,7 @@
 	rm drbd-utils-$(FDIST_VERSION)
 
 ifeq ($(FORCE),)
-tgz: check_changelogs_up2date drbdsetup
+tgz: check_changelogs_up2date doc
 endif
 
 tools doc tgz: check-submods
@@ -241,7 +237,7 @@
 config.status: configure
 	@printf "\nYou need to call ./configure with appropriate arguments (again).\n\n"; exit 1
 
-tarball: check-submods check_all_committed distclean drbdsetup configure .filelist
+tarball: check-submods check_all_committed distclean doc configure .filelist
 	$(MAKE) tgz
 
 ifdef RPMBUILD
__EOF
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
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
make .filelist
make rpmprep
#rpmbuild -bb --without 83support --without 84support --without manual drbd.spec
rpmbuild -bb --without 83support --without 84support drbd.spec

# build drbdmanage package
cd ~/Archive/drbdmanage
git checkout v0.99.16
make rpm
cp dist/*.noarch.rpm ~/rpmbuild/RPMS/noarch

# build drbdmanage-docker-volume
cd ~/Archive/drbdmanage-docker-volume
make doc
make rpm
cp dist/*.noarch.rpm ~/rpmbuild/RPMS/noarch

