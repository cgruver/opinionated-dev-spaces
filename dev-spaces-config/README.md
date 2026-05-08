
oc exec -n openshift-operators deploy/devspaces-operator -- cat /tmp/external_images.txt

```bash
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: devspaces
  namespace: openshift-operators
spec:
  channel: stable 
  installPlanApproval: Manual
  name: devspaces 
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kubernetes-imagepuller-operator 
  namespace: openshift-operators
spec:
  channel: stable 
  installPlanApproval: Manual
  name: kubernetes-imagepuller-operator 
  source: community-operators
  sourceNamespace: openshift-marketplace 
EOF
```
registry.redhat.io/devspaces/traefik-rhel9@sha256:b14ae96604856abc1148c51cb10a55993bbb466e0471f235c7a3d8d1e796394a
registry.redhat.io/devworkspace/devworkspace-project-clone-rhel9@sha256:9782d7a16befa43ab54c6a6c88431e5b1d6a432d72d77a049fd4548053c86ef3



ghcr.io/ansible/ansible-devspaces@sha256:ce1ecc3b3c350eab2a9a417ce14a33f4b222a6aafd663b5cf997ccc8c601fe2c
quay.io/che-incubator/che-code:insiders
quay.io/devfile/universal-developer-image:latest
quay.io/devspaces/dotnet-90@sha256:5cb201f58ebf20d76b7b99e013da46aa6cfe594c5763ab873bcc6436965d7859
registry.redhat.io/devspaces/code-rhel9@sha256:a0a9fcbe1b78d9d51dcb18ab46978a3a3cd04b5605aa93c4db3f689b71be2e0c
registry.redhat.io/devspaces/code-sshd-rhel9@sha256:01bb04c4b67c2e22d8d87b15086efc298f5e6782ab358a4949915ade0151778d
registry.redhat.io/devspaces/jetbrains-ide-rhel9@sha256:cfa7e9568e467dc4977b60bc63bcdc70b5998f16213754f85c8627ed34945836
registry.redhat.io/devspaces/udi-rhel9@sha256:7269df763e5ec427253931a8aaa6d9156d923644fc99326bab0dc55754f40d9f
