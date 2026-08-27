#!/usr/bin/env bash

# If the user's home dir does not exist, then create it.  this allows for configurable locations for user home.
if [ ! -d "${HOME}" ]
then
  mkdir -p "${HOME}"
fi

# Configure the container runtime to use an ephemeral graphroot, and to use fuse-overlay instead of vfs.
if [ ! -d "${HOME}/.config/containers" ]
then
  mkdir -p ${HOME}/.config/containers
  (echo '[storage]';echo 'driver = "overlay"';echo 'graphroot = "/tmp/graphroot"';echo '[storage.options.overlay]';echo 'mount_program = "/usr/bin/fuse-overlayfs"') > ${HOME}/.config/containers/storage.conf
fi

# Set up UID and GID mappings for the user
CURRENT_UID=$(id -u)
START_ID=$(( CURRENT_UID + 1 ))
NAMESPACE_SIZE=$(awk '{end=$1 + $3; if (end > max) max = end} END{print max}' /proc/self/uid_map)
SUB_ID_COUNT=$(( NAMESPACE_SIZE - START_ID ))
echo "$(whoami):${START_ID}:${SUB_ID_COUNT}" > /etc/subuid
echo "$(whoami):${START_ID}:${SUB_ID_COUNT}" > /etc/subgid

exec "$@"