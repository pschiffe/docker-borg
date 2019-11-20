FROM fedora:31

RUN dnf -y --setopt=install_weak_deps=False install \
        borgbackup \
        fuse-sshfs \
    && dnf clean all

ENV LANG en_US.UTF-8

COPY borg-backup.sh /

CMD [ "/borg-backup.sh" ]
