FROM fedora:25
MAINTAINER "Peter Schiffer" <pschiffe@redhat.com>

RUN dnf -y --setopt=tsflags=nodocs install \
        borgbackup \
        fuse-sshfs \
    && dnf clean all

ENV LANG en_US.UTF-8

COPY borg-backup.sh /

CMD [ "/borg-backup.sh" ]
