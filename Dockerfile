FROM centos:7 AS yum
ARG TARGETARCH

ENV BUILD_ARCH=$TARGETARCH

COPY yum /tmp/yum
RUN if [ "$BUILD_ARCH" = "amd64" ]; then \
    cp /tmp/yum/64/* /opt/; \
    else \
    cp /tmp/yum/other/* /opt/; \
    fi

FROM centos:7 AS builder
ARG TARGETARCH

ENV BUILD_ARCH=$TARGETARCH

RUN echo "$BUILD_ARCH" > /etc/BUILD_ARCH && \
    rm -f /etc/yum.repos.d/*

COPY --from=yum /opt/ /etc/yum.repos.d/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

SHELL ["/entrypoint.sh"]

RUN rpm --import http://mirror.nsc.liu.se/centos-store/RPM-GPG-KEY-CentOS-7 && \
    yum update -y --nogpgcheck && \
    yum clean all && \
    rm -rf /usr/share/locale && \
    rm -rf /var/cache/yum/*

RUN rm -f /etc/yum.repos.d/*
COPY --from=yum /opt/CentOS-Vault.repo /etc/yum.repos.d/

RUN if [ "$BUILD_ARCH" = "arm64" ]; then \
    rpm --import http://mirror.nsc.liu.se/centos-store/altarch/7.8.2003/os/aarch64/RPM-GPG-KEY-CentOS-7-aarch64; \
    NET_GPGKEY="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7-aarch64"; \
    elif [ "$BUILD_ARCH" = "arm" ]; then \
    rpm --import http://mirror.nsc.liu.se/centos-store/altarch/7.8.2003/os/armhfp/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32; \
    NET_GPGKEY="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-Arm32"; \
    elif [ "$BUILD_ARCH" = "ppc64le" ]; then \
    rpm --import http://mirror.nsc.liu.se/centos-store/altarch/7.8.2003/os/ppc64le/RPM-GPG-KEY-CentOS-SIG-AltArch-7-ppc64le; \
    NET_GPGKEY="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-AltArch-7-ppc64le"; \
    else \
    NET_GPGKEY="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7"; \
    fi && \
    sed -i "s|^gpgkey=.*|gpgkey=${NET_GPGKEY}|" /etc/yum.repos.d/CentOS-*.repo

FROM scratch
LABEL maintainer="Dely <dph5199278@163.com>" \
    name="CentOS Base Image" \
    license="GPLv2"

COPY --from=builder / /

ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]
