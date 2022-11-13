#!/bin/bash
KERNEL=$(yum info kernel-devel 2>/dev/null | awk '/^Arch/{ARCH=$3}/^Version/{VER=$3}/^Release/{REL=$3}END{print VER "-" REL "." ARCH}')
cd ~/Archive/drbd-9.0
DRBD_VERSION=$(git describe --tags)
cd ~/Archive/drbd-utils
UTIL_VERSION=$(git describe --tags)
echo $DRBD_VERSION-$UTIL_VERSION-$KERNEL
