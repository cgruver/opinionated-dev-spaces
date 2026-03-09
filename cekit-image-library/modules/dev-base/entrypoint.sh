#!/usr/bin/env bash

# Create Home directory
if [ ! -d "${HOME}" ]
then
  mkdir -p "${HOME}"
fi

# Create Podman configuration
if [ ! -d "${HOME}/.config/containers" ]; then
  mkdir -p ${HOME}/.config/containers
  (echo 'unqualified-search-registries = [';echo '  "registry.access.redhat.com",';echo '  "registry.redhat.io",';echo '  "docker.io"'; echo ']'; echo 'short-name-mode = "permissive"') > ${HOME}/.config/containers/registries.conf
  if [ -c "/dev/fuse" ] && [ -f "/usr/bin/fuse-overlayfs" ]; then
    (echo '[storage]';echo 'driver = "overlay"';echo 'graphroot = "/tmp/graphroot"';echo '[storage.options.overlay]';echo 'mount_program = "/usr/bin/fuse-overlayfs"') > ${HOME}/.config/containers/storage.conf
  else
    (echo '[storage]';echo 'driver = "vfs"') > "${HOME}"/.config/containers/storage.conf
  fi
fi

# Configure Z shell
if [ ! -f ${HOME}/.zshrc ]
then
  (echo "HISTFILE=${HOME}/.zsh_history"; echo "HISTSIZE=1000"; echo "SAVEHIST=1000") > ${HOME}/.zshrc
  (echo "if [ -f ${PROJECT_SOURCE}/workspace.rc ]"; echo "then"; echo "  . ${PROJECT_SOURCE}/workspace.rc"; echo "fi") >> ${HOME}/.zshrc
fi

# Configure Bash shell
if [ ! -f ${HOME}/.bashrc ]
then
  (echo "if [ -f ${PROJECT_SOURCE}/workspace.rc ]"; echo "then"; echo "  . ${PROJECT_SOURCE}/workspace.rc"; echo "fi") > ${HOME}/.bashrc
fi

exec "$@"
