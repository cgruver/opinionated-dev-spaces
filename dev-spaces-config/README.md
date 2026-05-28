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

oc delete configmap kilo-code-config -n devspaces
oc create configmap kilo-code-config --from-file=kilo.jsonc -n devspaces
oc label configmap kilo-code-config app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=workspaces-config -n devspaces
oc annotate configmap kilo-code-config controller.devfile.io/mount-as=subpath controller.devfile.io/mount-path=/globalconfig -n devspaces

oc create configmap roo-code-config --from-file=roo-code-settings.json --from-file=opencode.json -n devspaces
oc label configmap roo-code-config app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=workspaces-config -n devspaces
oc annotate configmap roo-code-config controller.devfile.io/mount-as=subpath controller.devfile.io/mount-path=/globalconfig -n devspaces
```
