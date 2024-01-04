# Borg Docker Image

![Docker Image Size (tag)](https://img.shields.io/docker/image-size/pschiffe/borg/latest?label=latest) ![Docker Pulls](https://img.shields.io/docker/pulls/pschiffe/borg)

This Docker image includes the [BorgBackup](https://borgbackup.readthedocs.io/en/stable/) client utility and sshfs support. Borg is a deduplicating archiver with compression and authenticated encryption. It's very efficient, doesn't require regular full backups, and supports data pruning.

Docker Hub: https://hub.docker.com/r/pschiffe/borg

Source GitHub repository: https://github.com/pschiffe/docker-borg

## Quick start

First, pull the image to keep it up to date. Then create and run the borg backup container. In this quick start, the `/etc` and `/home` directories from the host are bind mounted to the container as read only. These are the directories which will be backed up. The backed up data will be stored in the `borg-repo` Docker volume, and the data will be protected with the `my-secret-pw` password. If the host is using SELinux, use the `--security-opt label:disable` flag. This is because we don't want to relabel the `/etc` and `/home` directories, but we do want the container to have access to them. After the backup is done, data will be pruned according to the default policy and checked for errors. Borg runs in verbose mode within the container, which means it will print detailed output from the backup. At the end, the container is deleted. This is done using a separate `docker rm` command. We do this because the `--rm` option in `docker run` would also remove the Docker volumes, which we don't want. By deleting the container and pulling the image from the registry each time, we ensure the container is fresh for each backup run.
```
docker pull pschiffe/borg
docker run \
  -e BORG_REPO=/borg/repo \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e EXCLUDE='*/.cache*;*.tmp;/borg/data/etc/shadow' \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-config:/root \
  -v borg-repo:/borg/repo \
  -v /etc:/borg/data/etc:ro \
  -v /home:/borg/data/home:ro \
  --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
docker rm borg-backup
```

## More examples

Backup docker volumes to remote location (Borg must be running in server mode at that remote location):
```
docker run \
  -e BORG_REPO='user@hostname:/path/to/repo' \
  -e ARCHIVE=wordpress-$(date +%Y-%m-%d) \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-config:/root \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v wordpress-data:/borg/data/wordpress:ro \
  --name borg-backup \
  pschiffe/borg
```

Use sshfs if Borg is not installed on the remote location:
```
docker run \
  -e SSHFS='user@hostname:/path/to/repo' \
  -e SSHFS_PASSWORD=my-ssh-password \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-config:/root \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v wordpress-data:/borg/data/wordpress:ro \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
```

Using sshfs with ssh key authentication:
```
docker run \
  -e SSHFS='user@hostname:/path/to/repo' \
  -e SSHFS_IDENTITY_FILE=/root/ssh-key/key \
  -e SSHFS_GEN_IDENTITY_FILE=1 \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BACKUP_DIRS=/borg/data \
  -e COMPRESSION=lz4 \
  -e PRUNE=1 \
  -v borg-config:/root \
  -v mariadb-data:/borg/data/mariadb:ro \
  -v wordpress-data:/borg/data/wordpress:ro \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
```

Restoring files from a specific day to a folder on the host:
```
docker run \
  -e BORG_REPO='user@hostname:/path/to/repo' \
  -e ARCHIVE=wordpress-2016-05-25 \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e EXTRACT_TO=/borg/restore \
  -e EXTRACT_WHAT=only/this/file \
  -v borg-config:/root \
  -v /opt/restore:/borg/restore \
  --security-opt label:disable \
  --name borg-backup \
  pschiffe/borg
```

To run a custom Borg command, use the following syntax:
```
docker run \
  -e BORG_REPO='user@hostname:/path/to/repo' \
  -e BORG_PASSPHRASE=my-secret-pw \
  -e BORG_PARAMS='list ::2016-05-26' \
  -v borg-config:/root \
  --name borg-backup \
  pschiffe/borg
```

## Environment variables

Description of all accepted environment variables follows.

### Core variables

**BORG_REPO** - repository location

**ARCHIVE** - archive parameter for Borg repository. If empty, defaults to `"${HOSTNAME}_$(date +%Y-%m-%d)"`. For more info see [Borg documentation](https://borgbackup.readthedocs.io/en/stable/usage.html)

**BACKUP_DIRS** - directories to back up

**EXCLUDE** - paths/patterns to exclude from backup. Paths must be separated by `;`. For example: `-e EXCLUDE='/my path/one;/path two;*.tmp'`

**BORG_PARAMS** - run custom borg command inside of the container. If this variable is set, default commands are not executed, only the one specified in *BORG_PARAMS*. For example `list` or `list ::2016-05-26`. In both examples, repo is not specified, because borg understands the `BORG_REPO` env var and uses it by default

**BORG_SKIP_CHECK** - set to `1` if you want to skip the `borg check` command at the end of the backup

### Compression

**COMPRESSION** - compression to use. Defaults to lz4. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-create)

### Encryption

**BORG_PASSPHRASE** - `repokey` mode password. Defaults to none. Only the `repokey` mode encryption is supported by this Docker image. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-init)

### Extracting (restoring) files

**EXTRACT_TO** - directory where to extract (restore) borg archive. If this variable is set, default commands are not executed, only the extraction is done. Repo and archive are specified with *BORG_REPO* and *ARCHIVE* variables. [More info](https://borgbackup.readthedocs.io/en/stable/usage.html#borg-extract)

**EXTRACT_WHAT** - subset of files and directories which should be extracted

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

**SSHFS_GEN_IDENTITY_FILE** - if set, generates ssh key pair if *SSHFS_IDENTITY_FILE* is set and the key file doesn't exist. After generating the key, the public part of the key is printed to stdout and the container stops, so you have the chance to configure the server part before creating the first backup
