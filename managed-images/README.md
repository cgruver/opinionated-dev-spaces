# OpenShift Pipelines - Tekton

```yaml
apiVersion: v1                      
kind: Namespace                 
metadata:
  name: openshift-pipelines
--- 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-pipelines
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-pipelines
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
