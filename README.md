# Borg Docker Image

[![](https://imagelayers.io/badge/pschiffe/borg:latest.svg)](https://imagelayers.io/?images=pschiffe/borg:latest)

Docker image with [BorgBackup](https://borgbackup.readthedocs.io/en/stable/) client utility and sshfs support. Borg is a deduplicating backup program supporting compresion and encryption. It's very efficient and doesn't need regular full backups while still supporting data pruning.

## Quick start

First, pull the image to keep it up to date. Then create and run the borg backup container. In this quick start, the `/etc` and `/home` directories from the host are bind mounted to the container as read only. These are the directories which will be backed up. The backed up data will be stored in the `borg-repo` Docker volume, and the data will be protected with the `my-secret-pw` password. If the host is using SELinux, the `--security-opt label:disable` flag must be used, because we don't want to relabel the `/etc` and `/home` directories while we want the container to have access to them. After the backup is done, data will be pruned according to the default policy and checked for errors. Borg is running in a verbose mode within the container, so the detailed output from backup will be printed. At the end, the container is deleted. This is done by separate `docker rm` command, because the `--rm` option to the `docker run` would remove also the Docker volumes, and we don't want that. Deleting the container and pulling the image from registry every time keeps the container fresh every time the backup is run.
```
docker pull pschiffe/borg
docker run \
  -e BORG_REPO=/borg/repo \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-cache:/root/.cache/borg \
  -v borg-repo:/borg/repo \
  -v /etc:/borg/data/etc:ro \
  -v /home:/borg/data/home:ro \
  --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
docker rm borg-backup
```

## More examples

Backup docker volumes to remote location (Borg must be running in server mode in that remote location):
```
docker run \
  -e BORG_REPO='user@hostname:/path/to/repo' \
  -e ARCHIVE=wordpress-$(date +%Y-%m-%d) \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-cache:/root/.cache/borg \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v worpdress-data:/borg/data/wordpress:ro \
  --name borg-backup \
  pschiffe/borg
```

Using sshfs (in case when the Borg is not installed on the remote location):
```
docker run \
  -e SSHFS='user@hostname:/path/to/repo' \
  -e SSHFS_PASSWORD=my-ssh-password \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-cache:/root/.cache/borg \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v worpdress-data:/borg/data/wordpress:ro \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
```

Using sshfs with ssh key authentification:
```
docker run \
  -e SSHFS='user@hostname:/path/to/repo' \
  -e SSHFS_IDENTITY_FILE=/root/ssh-key/key \
  -e SSHFS_GEN_IDENTITY_FILE=1 \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-cache:/root/.cache/borg \
  -v borg-ssh-key:/root/ssh-key \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v worpdress-data:/borg/data/wordpress:ro \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
```

Running custom borg command:
```
docker run \
  -e BORG_REPO='user@hostname:/path/to/repo' \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BORG_PARAMS='list ::2016-05-26' \
  -v borg-cache:/root/.cache/borg \
  --name borg-backup \
  pschiffe/borg
```

## Environment variables

Description of all accepted environment variables follows.

### Core variables

**BORG_REPO** - repository location

**ARCHIVE** - archive parameter for Borg repository. If empty, defaults to `$(date +%Y-%m-%d)`. For more info see [Borg documentation](https://borgbackup.readthedocs.io/en/stable/usage.html)

**BACKUP_DIRS** - directories to back up

**BORG_PARAMS** - run custom borg command inside of the container. If this variable is set, default commands are not executed, only the one specified in *BORG_PARAMS*. For example `list` or `list ::2016-05-26`. In the second example, repo is not specified, because borg understands the `BORG_REPO` env var and uses it by default

### Compression

**COMPRESSION** - compression to use. Defaults to none. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-create)

### Encryption

**BORG_PASSPHRASE** - `repokey` mode password to encrypt the backed up data. Defaults to none. Only the `repokey` mode encryption is supported by this Docker image. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-init)

### Pruning

**PRUNE** - if set, prune the repository after backup. Empty by default. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-prune)

**PRUNE_PREFIX** - filter data to prune by prefix of the archive. Empty by default - prune all data

**KEEP_DAILY** - keep specified number of daily backups. Defaults to 7

**KEEP_WEEKLY** - keep specified number of weekly backups. Defaults to 4

**KEEP_MONTHLY** - keep specified number of monthly backups. Defaults to 6

### SSHFS

**SSHFS** - sshfs destination in form of `user@host:/path`. When using sshfs, container needs special permissions: `--cap-add SYS_ADMIN --device /dev/fuse` and if using SELinux: `--security-opt label:disable` or apparmor: `--security-opt apparmor:unconfined`

**SSHFS_PASSWORD** - password for ssh authentication

**SSHFS_IDENTITY_FILE** - path to ssh key

**SSHFS_GEN_IDENTITY_FILE** - if set, generates ssh key pair if *SSHFS_IDENTITY_FILE* is set, but the key file doesn't exist. 4096 bits long rsa key will be generated. After generating the key, the public part of the key is printed to stdout and the container stops, so you have the chance to configure the server part before running first backup
