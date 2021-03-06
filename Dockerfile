FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
RUN yum -y update \
    && yum -y groupinstall "Base" "Development Tools" \
    && yum -y install rpmdevtools libxslt libxslt-devel pygobject2 help2man epel-release po4a
RUN yum -y install kernel-devel kernel-abi-whitelists pandoc
RUN mv /usr/bin/uname /usr/bin/uname.org
COPY uname /usr/bin/uname
RUN chmod +x /usr/bin/uname
USER builder
RUN rpmdev-setuptree
RUN mkdir ${HOME}/Archive \
    && cd Archive \
    && git clone --recursive -b drbd-9.1.2 https://github.com/LINBIT/drbd-9.0.git \
    && git clone --recursive -b v9.16.0 https://github.com/LINBIT/drbd-utils.git
COPY build.sh .
ADD docbook-xsl-1.79.1.tar.gz .
ENV STYLESHEET_PREFIX file:///home/builder/docbook-xsl-1.79.1
CMD ["/bin/bash","./build.sh"]
