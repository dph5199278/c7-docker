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

FROM scratch
LABEL maintainer="Dely <dph5199278@163.com>" \
    name="CentOS Base Image" \
    license="GPLv2"

COPY --from=builder / /

ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]
