#!/bin/bash

set -euo pipefail

echoerr() { cat <<< "$@" 1>&2; }

if [ -n "${SSHFS:-}" ]; then
    if [ -n "${SSHFS_IDENTITY_FILE:-}" ]; then
        if [ ! -f "$SSHFS_IDENTITY_FILE" -a -n "${SSHFS_GEN_IDENTITY_FILE:-}" ]; then
            ssh-keygen -t rsa -b 4096 -N '' -f "$SSHFS_IDENTITY_FILE"
            cat "${SSHFS_IDENTITY_FILE}.pub"
            exit 0
        fi
        SSHFS_IDENTITY_FILE="-o IdentityFile=${SSHFS_IDENTITY_FILE}"
    else
        SSHFS_IDENTITY_FILE=''
    fi
    if [ -n "${SSHFS_PASSWORD:-}" ]; then
        SSHFS_PASSWORD="echo ${SSHFS_PASSWORD} |"
        SSHFS_PASSWORD_OPT='-o password_stdin'
    else
        SSHFS_PASSWORD=''
        SSHFS_PASSWORD_OPT=''
    fi
    mkdir -p /mnt/sshfs
    eval "${SSHFS_PASSWORD} sshfs -o StrictHostKeyChecking=no ${SSHFS} /mnt/sshfs ${SSHFS_IDENTITY_FILE} ${SSHFS_PASSWORD_OPT}"
    BORG_REPO=/mnt/sshfs
fi

if [ -z "${BORG_REPO:-}" ]; then
    echoerr 'Variable $BORG_REPO is required. Please set it to the repository location.'
    exit 1
fi

if [ -z "${BACKUP_DIRS:-}" ]; then
    echoerr 'Variable $BACKUP_DIRS is required. Please fill it with directories you would like to backup.'
    exit 1
fi

if [ -z "${BORG_PASSPHRASE:-}" ]; then
    INIT_ENCRYPTION='--encryption=none'
    echoerr 'Not using encryption. If you want to encrypt your files, set $BORG_PASSPHRASE variable.'
else
    INIT_ENCRYPTION=''
fi

# Borg just needs this
export BORG_REPO

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

borg create -v --stats $COMPRESSION ::"$ARCHIVE" $BACKUP_DIRS

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

    borg prune -v --stats $PRUNE_PREFIX --keep-daily=$KEEP_DAILY --keep-weekly=$KEEP_WEEKLY --keep-monthly=$KEEP_MONTHLY
fi

borg check -v

if [ -n "${SSHFS:-}" ]; then
    fusermount -u "$BORG_REPO"
fi
