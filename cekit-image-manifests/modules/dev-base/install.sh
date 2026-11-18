#!/usr/bin/env bash

set -e

pip install -U podman-compose
pip install -U cekit
chmod 755 /entrypoint.sh
#
# Setup for root-less podman
#
mkdir -p ${HOME}/.bin
groupadd -g 1000 user
useradd -u 1000 -g 1000 -d ${HOME} -s /bin/bash user
usermod -L user
chmod 400 /etc/shadow
chown -R 1000:1000 ${HOME}
echo "user:1:999" > /etc/subuid
echo "user:1:999" > /etc/subgid
echo "user:1001:64535" >> /etc/subuid
echo "user:1001:64535" >> /etc/subgid
setcap cap_setuid+ep /usr/bin/newuidmap
setcap cap_setgid+ep /usr/bin/newgidmap
if [ ! -f /workspace-init.sh ]
then
  echo 'echo "Setting workspace config"' > /workspace-init.sh
fi
chmod +x /workspace-init.sh