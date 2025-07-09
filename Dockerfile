FROM ubuntu:22.04

ENV container docker

RUN apt update && \
    apt install -y systemd systemd-sysv curl sudo gnupg2 lsb-release iproute2 iputils-ping net-tools rsync && \
    apt clean && \
    systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount && \
    rm -rf /var/lib/apt/lists/*

VOLUME [ "/sys/fs/cgroup", "/tmp", "/run" ]
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
