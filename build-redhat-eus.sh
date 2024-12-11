#!/bin/bash
# 1. prepare Azure VM 
#  offer: RHEL
#  publisher: RedHat
#  sku: '85-gen2'
#  version: latest
# 2. link opam build directory
# ensure /home partition size is enough to build
# if you have large /var partion, do
#   sudo mkdir /var/opam
#   sudo chown ${USER} /var/opam
#   ln -s /var/opam ~/.opam
# 2. then run this shell script
# 3. upload ~/drbd-9.1.12-v9.22.0-4.18.0-372.32.1.el8.x86_64.tar.gz to git release
set -xe
sudo dnf -y update 
sudo dnf -y groupinstall "Base" "Development Tools"
sudo dnf install -y rpmdevtools libxslt libxslt-devel pygobject2 selinux-policy-devel rubygems perl-CPAN
sudo dnf install -y kernel-rpm-macros elfutils-libelf-devel kernel-devel kernel-abi-whitelists  pkgconfig chrpath
echo | sudo bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
sudo install /dev/null /usr/local/bin/lbvers.py
cd ~
(echo;echo) | opam init
eval $(opam env --switch=default)
opam install ocamlfind
curl -L -O https://github.com/coccinelle/coccinelle/archive/refs/tags/1.3.0.tar.gz && tar xvzf 1.3.0.tar.gz
cd coccinelle-1.3.0
./autogen
./configure
make 
sudo make install
mkdir -p ~/rpmbuild/SOURCES
export PYTHONPATH=/usr/local/lib/coccinelle/python
mkdir ~/Archive
cd  ~/Archive
git clone --recursive -b drbd-9.1.12 https://github.com/LINBIT/drbd.git
cd drbd
make tarball
make kmp-rpm
cd ~
curl -LO https://github.com/procube-open/drbd9-rpm/raw/master/docbook-xsl-1.79.1.tar.gz
tar xvzf docbook-xsl-1.79.1.tar.gz
export STYLESHEET_PREFIX=file://${HOME}/docbook-xsl-1.79.1
sudo gem install asciidoctor
git clone https://github.com/mquinson/po4a.git
cd po4a/
perl Build.PL
yes | sudo ./Build installdeps
./Build 
sudo ./Build install
cd ~/Archive
git clone --recursive -b  v9.22.0 https://github.com/LINBIT/drbd-utils.git
cd drbd-utils
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --without-manual  --without-83support --without-84support --without-drbdmon --without-manual
UTIL_VERSION=$(sed -n -e "s/^PACKAGE_VERSION='\(.*\)'/\1/p" configure)
make tarball VERSION=${UTIL_VERSION}
cp drbd-utils-${UTIL_VERSION}.tar.gz  ~/rpmbuild/SOURCES/
./configure --enable-spec
sed -i -e 's/^BuildRequires: po4a/#BuildRequires: po4a/' drbd.spec
rpmbuild -bb --without sbinsymlinks --without heartbeat --without 83support --without 84support drbd.spec
cd ~/rpmbuild
tar cvzf ~/drbd-9.1.12-v9.22.0-4.18.0-372.32.1.el8.x86_64.tar.gz RPMS
