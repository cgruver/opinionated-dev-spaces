# Notes

Login as cluster-admin

```bash
oc login -u=admin $(oc whoami --show-server)
podman login -u $(oc whoami) -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000
```
