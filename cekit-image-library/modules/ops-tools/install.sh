#!/usr/bin/env bash

TEMP_DIR="$(mktemp -d)" 
mkdir -p /usr/local/quarkus-cli/lib 
mkdir /usr/local/quarkus-cli/bin 
curl -fsSL -o ${TEMP_DIR}/tkn.tgz https://github.com/tektoncd/cli/releases/download/v${TEKTON_CLI_VERSION}/tkn_${TEKTON_CLI_VERSION}_Linux_x86_64.tar.gz
tar -xzf ${TEMP_DIR}/tkn.tgz -C ${TEMP_DIR} 
cp ${TEMP_DIR}/tkn /usr/local/bin/tkn 
chmod +x /usr/local/bin/tkn  
curl -fsSL -o ${TEMP_DIR}/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/${ARGO_CD_VERSION}/argocd-linux-amd64
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm -rf "${TEMP_DIR}" 