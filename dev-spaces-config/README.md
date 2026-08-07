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

```bash
oc exec -n openshift-operators deploy/devspaces-operator -- cat /tmp/external_images.txt
```

```bash
oc create configmap ansible-devspace --from-file=ansible-devspace.json -n devspaces
oc label configmap ansible-devspace app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=getting-started-samples -n devspaces
```

```bash
oc login -u=admin $(oc whoami --show-server)
oc create configmap ai-tools-config --from-file=opencode.json --from-file=zoo-code-settings.json -n devspaces
oc label configmap ai-tools-config app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=workspaces-config -n devspaces
oc annotate configmap ai-tools-config controller.devfile.io/mount-as=subpath controller.devfile.io/mount-path=/globalconfig -n devspaces


oc delete configmap kilo-code-config -n devspaces
oc create configmap kilo-code-config --from-file=kilo.jsonc -n devspaces
oc label configmap kilo-code-config app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=workspaces-config -n devspaces
oc annotate configmap kilo-code-config controller.devfile.io/mount-as=subpath controller.devfile.io/mount-path=/globalconfig -n devspaces
```

```
images: 'traefik-rhel9=registry.redhat.io/devspaces/traefik-rhel9@sha256:b14ae96604856abc1148c51cb10a55993bbb466e0471f235c7a3d8d1e796394a;devworkspace-project-clone-rhel9=registry.redhat.io/devworkspace/devworkspace-project-clone-rhel9@sha256:9782d7a16befa43ab54c6a6c88431e5b1d6a432d72d77a049fd4548053c86ef3;che-code-insiders=quay.io/che-incubator/che-code:insiders;code-rhel9=registry.redhat.io/devspaces/code-rhel9@sha256:a0a9fcbe1b78d9d51dcb18ab46978a3a3cd04b5605aa93c4db3f689b71be2e0c'

images: 'ansible-devspaces-0=ghcr.io/ansible/ansible-devspaces@sha256:d2ea3e53c2abe1b23cc42fb3930b878df776c83d12bcb41d8ac508a3db9838e4;che-code-1=quay.io/che-incubator/che-code:insiders;universal-developer-image-2=quay.io/devfile/universal-developer-image:latest;dotnet-90-3=quay.io/devspaces/dotnet-90@sha256:5cb201f58ebf20d76b7b99e013da46aa6cfe594c5763ab873bcc6436965d7859;code-rhel9-4=registry.redhat.io/devspaces/code-rhel9@sha256:11a105b3192f7e1dc0368ae9b5b79b206798164d6a7071a5aecf2cf71c525ca7;code-sshd-rhel9-5=registry.redhat.io/devspaces/code-sshd-rhel9@sha256:2472040b199dc9cbcf3cc9ca9c93f24a349abd916d572e54f9779a0a3a1c4769;jetbrains-ide-rhel9-6=registry.redhat.io/devspaces/jetbrains-ide-rhel9@sha256:faa2e36100d7062a27b7dcce26622ad274fe120bd58868007ab0ff850c7d4d50;udi-rhel9-7=registry.redhat.io/devspaces/udi-rhel9@sha256:11a7bfc7ad6bdd91f2acfe3d7a2b84f24161f5e5be66746ec29831f9f99e5c34;'

```

```bash
CSV=$(oc get csv -n openshift-operators -o name | grep devspaces)
che_code=$(oc get ${CSV} -n openshift-operators -o jsonpath='{.spec.relatedImages[?(@.name=="editor_definition_che_code_latest_che_code_injector")].image}')
traefik=$(oc get ${CSV} -n openshift-operators -o jsonpath='{.spec.relatedImages[?(@.name=="single_host_gateway")].image}')
CSV=$(oc get csv -n openshift-operators -o name | grep devworkspace)
project_clone=$(oc get ${CSV} -n openshift-operators -o jsonpath='{.spec.relatedImages[?(@.name=="project_clone")].image}')
cat << EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: PinnedImageSet
metadata:
  name: devspaces-images
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  pinnedImages:
  - name: ${che_code}
  - name: ${traefik}
  - name: ${project_clone}
EOF
```


```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: registry-puller
  namespace: cekit-images
---
apiVersion: v1
kind: Secret
metadata:
  name: internal-registry-token
  namespace: cekit-images
  annotations:
    kubernetes.io/service-account.name: "registry-puller"
type: kubernetes.io/service-account-token
```

```
oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > global-pull-secret.json

oc get secret registry-puller-dockercfg-lz5h6 -n cekit-images --template='{{index .data ".dockercfg" | base64decode}}' | jq -r '."image-registry.openshift-image-registry.svc:5000".auth' | base64 -d

oc registry login --registry="image-registry.openshift-image-registry.svc:5000" --auth-basic="system:serviceaccount:cekit-images:registry-puller:$(oc get secret internal-registry-token -n cekit-images -o jsonpath='{.data.token}' | base64 --decode)" --to=global-pull-secret.json
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./global-pull-secret.json
```

```bash
oc get installplan -o jsonpath='{range .items[?(@.spec.approved==false)]}{.metadata.name},{.spec.clusterServiceVersionNames}{"\n"}{end}'

oc get csv devspacesoperator.v3.29.1 -n openshift-operators -o jsonpath='{.spec.relatedImages}' | jq

oc get csv devspacesoperator.v3.29.1 -n openshift-operators -o jsonpath='{range .items[?(@.spec.relatedImages.name==editor_definition_che_code_latest_che_code_injector)]  .spec.relatedImages}'

oc get csv devspacesoperator.v3.29.1 -n openshift-operators -o jsonpath='{.spec.relatedImages}{range .items[?(@.name==editor_definition_che_code_latest_che_code_injector)]}{.image}'

oc get csv devspacesoperator.v3.29.1 -n openshift-operators -o json | jq -r '.spec.relatedImages[] | select(.name == "editor_definition_che_code_latest_che_code_injector") | .image'

oc get csv devspacesoperator.v3.29.1 -n openshift-operators -o jsonpath='{.spec.relatedImages[?(@.name=="editor_definition_che_code_latest_che_code_injector")].image}'

editor_definition_che_code_latest_che_code_injector
editor_definition_che_code_latest_che_code_runtime_description

oc get csv devworkspace-operator.v0.42.0  -n openshift-operators -o jsonpath='{.spec.relatedImages}' | jq
project_clone
```

Test extra PVC

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
    controller.devfile.io/mount-path: /extra-pvc
  name: extra-storage
  namespace: cgruver-devspaces
  labels:
    controller.devfile.io/mount-to-devworkspace: "true"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: qnap-iscsi
  volumeMode: Filesystem
```


