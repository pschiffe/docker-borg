FROM fedora:43

RUN echo 'install_weak_deps=False' >> /etc/dnf/dnf.conf \
  && echo 'assumeyes=True' >> /etc/dnf/dnf.conf \
  && sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-openh264.repo \
  && dnf --refresh upgrade \
  && dnf install \
    borgbackup \
    fuse-sshfs \
  && dnf clean all

ENV LANG=en_US.UTF-8

COPY borg-backup.sh /

CMD [ "/borg-backup.sh" ]
