#!/bin/bash
set -x
# build drbd-9 package
cd ~/Archive/drbd-9.0
make .filelist
make kmp-rpm
# build drbd-utils package
cd ~/Archive/drbd-utils
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

# build drbdmanage package
cd ~/Archive/drbdmanage
make rpm
cp dist/*.noarch.rpm ~/rpmbuild/RPMS/noarch

# build drbdmanage-docker-volume
cd ~/Archive/drbdmanage-docker-volume
patch -p 0 << '__EOF'
--- drbdmanage-docker-volume	2018-04-08 10:41:53.574010303 +0900
+++ drbdmanage-docker-volume.new	2018-04-08 20:31:52.276689284 +0900
@@ -103,13 +103,18 @@

     def get_request(self):
         length = int(self.headers['content-length'])
-        return json.loads(self.rfile.read(length))
+        jsonstr = self.rfile.read(length)
+        print 'length: %d, request: %s\n' % (length, jsonstr)
+        if length == 0:
+            return {};
+        return json.loads(jsonstr)

-    def respond(self, msg):
-        self.send_response(200)
+    def respond(self, msg, status=200):
+        self.send_response(status)
         self.send_header('Content-type', 'application/vnd.docker.plugins.v1+json')
         self.end_headers()
-        print 'Responding with', json.dumps(msg)
+        print 'Responding with %s status = %d\n' % (json.dumps(msg), status)
+        sys.stdout.flush()
         self.wfile.write(json.dumps(msg))

     def do_POST(self):
@@ -118,11 +123,11 @@
             return

         request = self.get_request()
-        print request
         if 'Name' in request:
             name = request['Name']
             mountpoint = self.getmountpoint(name)
         err_msg = ''
+        status = 200

         if self.path == '/VolumeDriver.Create':
             fs = fs_opts = size = deploy_hosts = deploy_count = False
@@ -164,6 +169,7 @@
                 if success:
                     ret = 0
                     path = self.dm.local_path(name)
+                    os.system('drbdadm status %s' % (name))
                     while True:
                         try:
                             with open(path, 'w') as dev:
@@ -172,15 +178,18 @@
                                 break
                         except IOError:
                             time.sleep(2)
+                    os.system('drbdadm status %s' % (name))

                     ret = os.system('wipefs -a %s' % (path))
                     ret = os.system('mkfs -t %s %s %s' % (fs, fs_opts, path))
                     if ret != 0:
                         err_msg = "Could not format %s (%s) as %s" % (name, path, fs)
+                        status = 500
                 else:
                     err_msg = 'Could not create volume %s' % (name)
+                    status = 500

-            self.respond({'Err': err_msg})
+            self.respond({'Err': err_msg}, status)

         elif self.path == '/VolumeDriver.Mount':
             if self.res_exists(name):
@@ -192,14 +201,16 @@
                     ret = os.system('mount %s %s' % (path, mountpoint))
                     if ret != 0:
                         err_msg = 'Could not mount %s to %s' % (path, mountpoint)
+                        status = 500
                     else:
                         self.mounts[name] = 1
                 else:
                     self.mounts[name] += 1
             else:
                 err_msg = 'Volume %s does not exist' % (name)
+                status = 404

-            self.respond({'Mountpoint': mountpoint, 'Err': err_msg})
+            self.respond({'Mountpoint': mountpoint, 'Err': err_msg}, status)

         elif self.path == "/VolumeDriver.Unmount":
             if self.res_exists(name):
@@ -215,12 +226,16 @@
                                 pass
                         else:
                             err_msg = 'Could not umount %s (%s)' % (name, mountpoint)
+                            status = 500
+                    else:
+                        err_msg = 'Could not umount %s (%s) is not mounted' % (name, mountpoint)
                 else:
-                    err_msg = 'Could not umount %s (%s) is not mounted' % (name, mountpoint)
+                    err_msg = 'Could not umount %s has no mountpoint' % (name)
             else:
                 err_msg = 'Volume %s does not exist' % (name)
+                status = 404

-            self.respond({'Err': err_msg})
+            self.respond({'Err': err_msg}, status)

         elif self.path == '/VolumeDriver.Remove':
             if self.res_exists(name):
@@ -233,12 +248,15 @@
                         self.mounts.pop(name, None)
                     else:
                         err_msg = 'Could not remove %s' % (name)
+                        status = 500
                 else:
                     err_msg = 'Can not remove Volume %s, still in use' % (name)
+                    status = 500
             else:
                 err_msg = 'Can not remove Volume %s, because it does not exist' % (name)
+                status = 404

-            self.respond({'Err': err_msg})
+            self.respond({'Err': err_msg}, status)

         elif self.path == '/VolumeDriver.Path':
             self.respond({'Mountpoint': mountpoint, 'Err': ''})
@@ -249,7 +267,7 @@
                     {'Volume': {'Name': name, 'Mountpoint': mountpoint},
                      'Err': ''})
             else:
-                self.respond({'Err': 'Volume %s does not exist' % (name)})
+                self.respond({'Err': 'Volume %s does not exist' % (name)}, 404)

         elif self.path == '/VolumeDriver.List':
             rl = self.dm.list_resource_names(dm_utils.dict_to_aux_props(
@@ -259,21 +277,24 @@
             result = [{'Name': v, 'Mountpoint': self.getmountpoint(v)} for v in rl]
             self.respond({'Volumes': result, 'Err': ''})

+        elif self.path == '/VolumeDriver.Capabilities':
+            self.respond({'Capabilities': {'Scope': 'global'}})
+
         else:
-            print 'Unknown API call:', self.path
-            self.respond({'Err': 'Unknown API call %s' % (self.path)})
+            print 'Unknown API call:', self.path, '\n'
+            self.respond({'Err': 'Unknown API call %s' % (self.path)}, 501)


 if __name__ == '__main__':
     if not sys.platform.startswith('linux'):
-        print 'This is a GNU/Linux only plugin'
+        print 'This is a GNU/Linux only plugin\n'
         sys.exit(1)

     makedirs(MOUNT_DIRECTORY)
     makedirs(PLUGIN_DIRECTORY)

     server = UDSServer(PLUGIN_SOCKET, DockerHandler)
-    print 'Starting server, use <Ctrl-C> to stop'
+    print 'Starting server, use <Ctrl-C> to stop\n'
     try:
         server.serve_forever()
     except KeyboardInterrupt:
__EOF
make doc
make rpm
cp dist/*.noarch.rpm ~/rpmbuild/RPMS/noarch
