FROM fedora:25
MAINTAINER "Peter Schiffer" <pschiffe@redhat.com>

RUN dnf -y --setopt=tsflags=nodocs install \
        borgbackup \
        fuse-sshfs \
    && dnf clean all

COPY borg-backup.sh /

CMD [ "/borg-backup.sh" ]
