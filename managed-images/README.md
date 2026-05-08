# OpenShift Pipelines - Tekton

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel:  latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

```bash
oc apply -f cekit-build-setup.yaml
oc apply -f cekit-build-task.yaml
oc secrets link builder nexus-pull-secret --for=pull -n cekit-build
oc start-build cekit-builder -n cekit-build -w -F
```