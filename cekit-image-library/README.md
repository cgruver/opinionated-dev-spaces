
```bash
cekit --descriptor images/developer/base-dev-ubi9.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:ubi9
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:ubi9

cekit --descriptor images/developer/base-dev-ubi10.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:ubi10
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:ubi10

cekit --descriptor images/developer/base-dev-fedora.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/workspace-base:fedora
podman push nexus.clg.lab:5002/dev-spaces/workspace-base:fedora

cekit --descriptor images/developer/vscode-dev.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/vscode-dev:latest
podman push nexus.clg.lab:5002/dev-spaces/vscode-dev:latest

cekit --descriptor images/developer/vscode-builder.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/vscode-builder:latest
podman push nexus.clg.lab:5002/dev-spaces/vscode-builder:latest

cekit --descriptor images/developer/ops-tools.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/ops-tools:latest
podman push nexus.clg.lab:5002/dev-spaces/ops-tools:latest

cekit --descriptor images/developer/ai-home-lab.yaml build podman --tag nexus.clg.lab:5002/dev-spaces/ai-home-lab:latest
podman push nexus.clg.lab:5002/dev-spaces/ai-home-lab:latest
```
