#!/usr/bin/env bash

TEMP_DIR="$(mktemp -d)" 
curl -fsSL -o ${TEMP_DIR}/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz
tar -xzf ${TEMP_DIR}/nvim-linux-x86_64.tar.gz -C ${TEMP_DIR} 
cp ${TEMP_DIR}/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
cp -r ${TEMP_DIR}/nvim-linux-x86_64/lib /usr/local
cp -r ${TEMP_DIR}/nvim-linux-x86_64/share /usr/local
chmod + /usr/local/bin/nvim
rm -rf "${TEMP_DIR}"
