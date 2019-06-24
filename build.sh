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
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
make .filelist
make rpm
#make rpmprep
#rpmbuild -bb --without 83support --without 84support --without manual drbd.spec
# rpmbuild -bb --without 83support --without 84support drbd.spec


