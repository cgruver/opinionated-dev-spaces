#!/usr/bin/env bash

TEMP_DIR="$(mktemp -d)"
GH_VERSION=$(basename $(curl -LsI -o /dev/null -w %{url_effective} https://github.com/cli/cli/releases/latest) | cut -d'v' -f2)
GH_ARCH="linux_amd64"
GH_TGZ_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_${GH_ARCH}.tar.gz"
curl -fsSL -o ${TEMP_DIR}/gh.tgz "${GH_TGZ_URL}"
tar -zxf ${TEMP_DIR}/gh.tgz -C ${TEMP_DIR}
mv ${TEMP_DIR}/gh_${GH_VERSION}_${GH_ARCH}/bin/gh /usr/local/bin/
chmod +x /usr/local/bin/gh
rm -rf "${TEMP_DIR}"
