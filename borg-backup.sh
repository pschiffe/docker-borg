#!/bin/bash

set -euo pipefail

echoerr() { cat <<< "$@" 1>&2; }

if [ -n "${SSHFS:-}" ]; then
    mkdir -p /mnt/sshfs
    sshfs "$SSHFS" /mnt/sshfs
    BORG_REPO=/mnt/sshfs
fi

if [ -z "${BORG_REPO:-}" ]; then
    echoerr 'Variable $BORG_REPO is required. Please set it to the repository location.'
fi

if [ -z "${BORG_PASSPHRASE:-}" ]; then
    INIT_ENCRYPTION='--encryption=none'
    echoerr 'Not using encryption. If you want to encrypt your files, set $BORG_PASSPHRASE variable.'
else
    INIT_ENCRYPTION=''
fi

# If the $BORG_REPO is a local path and the directory is empty, init it
if [ "${BORG_REPO:0:1}" == '/' -a ! "$(ls -A $BORG_REPO)" ]; then
    INIT_REPO=1
fi

if [ -n "${INIT_REPO:-}" ]; then
    borg init $INIT_ENCRYPTION
fi

TODAY=$(date +%Y-%m-%d)
ARCHIVE="${ARCHIVE:-$TODAY}"

if [ -n "${COMPRESSION:-}" ]; then
    COMPRESSION="--compression=${COMPRESSION}"
else
    COMPRESSION=''
fi

borg create $COMPRESSION ::"$ARCHIVE" $BACKUP_DIRS

if [ -n "${PRUNE:-}" ]; then
    if [ -n "${PRUNE_PREFIX:-}" ]; then
        PRUNE_PREFIX="--prefix=${PRUNE_PREFIX}"
    else
        PRUNE_PREFIX=''
    fi
    if [ -z "${KEEP_DAILY:-}" ]; then
        KEEP_DAILY=7
    fi
    if [ -z "${KEEP_WEEKLY:-}" ]; then
        KEEP_WEEKLY=4
    fi
    if [ -z "${KEEP_MONTHLY:-}" ]; then
        KEEP_MONTHLY=6
    fi

    borg prune $PRUNE_PREFIX --keep-daily=$KEEP_DAILY --keep-weekly=$KEEP_WEEKLY --keep-monthly=$KEEP_MONTHLY
fi

borg check

if [ -n "${SSHFS:-}" ]; then
    fusermount -u "$BORG_REPO"
fi
