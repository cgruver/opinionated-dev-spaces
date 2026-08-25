# Notes

Login as cluster-admin

```bash
oc login -u=admin $(oc whoami --show-server)
podman login -u $(oc whoami) -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000
```

deployment:
        containers:
          - image: 'quay.io/redhat-user-workloads/devspaces-tenant/devspaces/dashboard-rhel9:fd837ebcee840e2d42b49e24dbffc0dafa2e3aa2'