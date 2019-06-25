#!/bin/bash
set -x
# build drbd-9 package
cd ~/Archive/drbd-9.0
make .filelist
make kmp-rpm
# build drbd-utils package
cd ~/Archive/drbd-utils
patch -u Makefile.in << '__EOF'
--- Makefile.in	2019-06-24 13:28:31.651645721 +0000
+++ Makefile.in.new	2019-06-24 13:29:20.523507004 +0000
@@ -300,14 +300,14 @@
 .PHONY: rpm
 rpm: rpmprep
 	$(RPMBUILD) -bb \
-	    --with prebuiltman $(RPMOPT) \
+	    $(RPMOPT) \
 	    drbd.spec
 	@echo "You have now:" ; find `rpm -E "%_rpmdir"` -name *.rpm

 .PHONY: srpm
 srpm: rpmprep
 	$(RPMBUILD) -bs \
-		--with prebuiltman $(RPMOPT) \
+		$(RPMOPT) \
 		drbd.spec
 	@echo "You have now:" ; find `rpm -E "%_srcrpmdir"` -name *.src.rpm
 endif
__EOF
patch -p 0 << '__EOF'
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
make rpm
#make rpmprep
#rpmbuild -bb --without 83support --without 84support --without manual drbd.spec
# rpmbuild -bb --without 83support --without 84support drbd.spec


