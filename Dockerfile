FROM fedora:23
MAINTAINER "Peter Schiffer" <pschiffe@redhat.com>

RUN dnf -y --setopt=tsflags=nodocs install \
        borgbackup \
        fuse-sshfs \
    && dnf -y clean all

COPY borg-backup.sh /bin/

CMD [ "borg-backup.sh" ]
