
```bash
cekit --descriptor images/developer/base-dev-ubi9.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:ubi9
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:ubi9

cekit --descriptor images/developer/base-dev-ubi10.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:ubi10
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:ubi10

cekit --descriptor images/developer/base-dev-fedora.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:fedora
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:fedora

cekit --descriptor images/app-product/vscode-dev.yaml build podman --build-flag --volume --build-flag /tmp/node-extra-certificates/ca.crt:/tmp/node-extra-certificates/ca.crt:Z --build-arg NODE_EXTRA_CA_CERTS=/tmp/node-extra-certificates/ca.crt --tag nexus.clg.lab:5002/dev-spaces/vscode-dev:latest
podman push nexus.clg.lab:5002/dev-spaces/vscode-dev:latest

cekit --descriptor images/utility/vscode-builder.yaml build podman --build-flag --volume --build-flag /tmp/node-extra-certificates/ca.crt:/tmp/node-extra-certificates/ca.crt:Z --build-arg NODE_EXTRA_CA_CERTS=/tmp/node-extra-certificates/ca.crt --tag nexus.clg.lab:5002/dev-spaces/vscode-builder:latest
podman push nexus.clg.lab:5002/dev-spaces/vscode-builder:latest

cekit --descriptor images/developer/ops-tools.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/ops-tools:latest
podman push nexus.clg.lab:5002/dev-spaces/ops-tools:latest

cekit --descriptor images/app-product/ai-home-lab.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/ai-home-lab:latest
podman push nexus.clg.lab:5002/dev-spaces/ai-home-lab:latest

cekit --descriptor images/app-product/cajun-navy.yaml build podman --build-flag --volume --build-flag /tmp/node-extra-certificates/ca.crt:/tmp/node-extra-certificates/ca.crt:Z --build-arg NODE_EXTRA_CA_CERTS=/tmp/node-extra-certificates/ca.crt --tag nexus.clg.lab:5002/dev-spaces/cajun-navy:latest
podman push --cert-dir /public-certs nexus.clg.lab:5002/dev-spaces/cajun-navy:latest

cekit --descriptor images/app-product/che-demo-app.yaml build podman --build-flag --volume --build-flag /tmp/node-extra-certificates/ca.crt:/tmp/node-extra-certificates/ca.crt:Z --build-arg NODE_EXTRA_CA_CERTS=/tmp/node-extra-certificates/ca.crt --tag nexus.clg.lab:5002/dev-spaces/che-demo-app:latest
podman push --cert-dir /public-certs nexus.clg.lab:5002/dev-spaces/che-demo-app:latest
```
