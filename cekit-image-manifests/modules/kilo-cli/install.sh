#!/usr/bin/env bash
set -e
npm install -g @kilocode/cli

cat << EOF >> /workspace-init.sh
if [ -f /globalconfig/kilo.jsonc ]
then
  if [ ! -d ${HOME}/.config/kilo ]
  then
    mkdir -p ${HOME}/.config/kilo
    cp /globalconfig/kilo.jsonc ${HOME}/.config/kilo/kilo.jsonc
  fi
fi
EOF
