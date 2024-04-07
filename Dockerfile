# stage 1
FROM nvidia/cuda:12.3.2-devel-centos7 as build
ARG version
ARG commit

RUN curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
    tee /etc/yum.repos.d/nvidia-container-toolkit.repo
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

RUN yum install -y libvdpau-devel rpm-build

COPY cmake-3.29.0-linux-x86_64.tar.gz cmake-3.29.0-linux-x86_64.tar.gz
RUN tar xf cmake-3.29.0-linux-x86_64.tar.gz && \
    mv cmake-3.29.0-linux-x86_64/ /usr/local/cmake-3.29.0
ENV PATH="/usr/local/cmake-3.29.0/bin:${PATH}"

COPY cuda-control.tar /tmp

RUN cd /tmp && tar xvf /tmp/cuda-control.tar && \
    cd /tmp/cuda-control && mkdir vcuda-${version} && \
    cd vcuda-${version} && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make

RUN cd /tmp/cuda-control && tar cf /tmp/vcuda.tar.gz -c vcuda-${version}

# stage 2
RUN mkdir -p /root/rpmbuild/{SPECS,SOURCES}

COPY vcuda.spec /root/rpmbuild/SPECS
RUN cp /tmp/vcuda.tar.gz /root/rpmbuild/SOURCES

RUN echo '%_topdir /root/rpmbuild' > /root/.rpmmacros \
  && echo '%__os_install_post %{nil}' >> /root/.rpmmacros \
  && echo '%debug_package %{nil}' >> /root/.rpmmacros

WORKDIR /root/rpmbuild/SPECS

RUN rpmbuild -bb --quiet \
  --define 'version '${version}'' \
  --define 'commit '${commit}'' \
  vcuda.spec

# stage 3
FROM centos:7

ARG version
ARG commit

COPY --from=build  /root/rpmbuild/RPMS/x86_64/vcuda-${version}-${commit}.el7.x86_64.rpm /tmp
RUN rpm -ivh /tmp/vcuda-${version}-${commit}.el7.x86_64.rpm && rm -rf /tmp/vcuda-${version}-${commit}.el7.x86_64.rpm
