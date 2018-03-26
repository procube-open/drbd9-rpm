FROM procube/centos-standalone-base:latest
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
RUN yum -y update \
    && yum -y groupinstall "Base" "Development Tools" \
    && yum -y install rpmdevtools libxslt libxslt-devel pygobject2 help2man
RUN yum -y install kernel-devel-$(uname -r) kernel-abi-whitelists
USER builder
RUN rpmdev-setuptree
RUN mkdir ${HOME}/Archive \
    && cd Archive \
    && git clone --recursive https://github.com/LINBIT/drbd-9.0.git \
    && git clone --recursive https://github.com/LINBIT/drbd-utils.git \
    && git clone --recursive https://github.com/LINBIT/drbdmanage.git
COPY build.sh .
CMD ["/bin/bash","./build.sh"]
