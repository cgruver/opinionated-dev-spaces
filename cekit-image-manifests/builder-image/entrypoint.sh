#!/usr/bin/env bash

# Create Home directory
if [ ! -d "${HOME}" ]
then
  mkdir -p "${HOME}"
fi

# Create Podman configuration
mkdir -p ${HOME}/.config/containers
(echo '[storage]';echo 'driver = "overlay"';echo 'graphroot = "/tmp/graphroot"';echo '[storage.options.overlay]';echo 'mount_program = "/usr/bin/fuse-overlayfs"') > ${HOME}/.config/containers/storage.conf

exec "$@"
