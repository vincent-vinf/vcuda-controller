# stage 1
FROM nvidia/cuda:12.3.2-devel-ubuntu20.04 as build

RUN apt update && apt install -y --no-install-recommends \
  curl

RUN curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
# 清华大学镜像源
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  cmake libvdpau-dev && \
  rm -rf /var/lib/apt/lists/*

COPY cuda-control.tar /tmp

ARG version

RUN cd /tmp && tar xvf /tmp/cuda-control.tar && \
    cd /tmp/cuda-control && mkdir vcuda-${version} && \
    cd vcuda-${version} && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make

RUN cd /tmp/cuda-control && tar cf /tmp/vcuda.tar.gz -c vcuda-${version}

# stage 2
FROM centos:7 as rpmpkg

RUN yum install -y rpm-build
RUN mkdir -p /root/rpmbuild/{SPECS,SOURCES}

COPY vcuda.spec /root/rpmbuild/SPECS
COPY --from=build /tmp/vcuda.tar.gz /root/rpmbuild/SOURCES

RUN echo '%_topdir /root/rpmbuild' > /root/.rpmmacros \
  && echo '%__os_install_post %{nil}' >> /root/.rpmmacros \
  && echo '%debug_package %{nil}' >> /root/.rpmmacros

WORKDIR /root/rpmbuild/SPECS

ARG version
ARG commit

RUN rpmbuild -bb --quiet \
  --define 'version '${version}'' \
  --define 'commit '${commit}'' \
  vcuda.spec

# stage 3
FROM centos:7

ARG version
ARG commit

COPY --from=rpmpkg  /root/rpmbuild/RPMS/x86_64/vcuda-${version}-${commit}.el7.x86_64.rpm /tmp
RUN rpm -ivh /tmp/vcuda-${version}-${commit}.el7.x86_64.rpm && rm -rf /tmp/vcuda-${version}-${commit}.el7.x86_64.rpm
