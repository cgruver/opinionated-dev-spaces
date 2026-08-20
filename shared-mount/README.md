# Adding shared storage to workspaces

## Extra PVC

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
    controller.devfile.io/mount-path: /<DESIRED_MOUNT_PATH> # example - /projects/shared
  name: shared-workspace-volume
  labels:
    controller.devfile.io/mount-to-devworkspace: "true"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  storageClassName: <STORAGE_CLASS_THAT_SUPPORTS_RWX>
```

## Extra PVC added globally

```yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: devspaces-user-shared-pvc
  labels:
    app.kubernetes.io/part-of: che.eclipse.org
    app.kubernetes.io/component: workspaces-config
objects:
- kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    annotations:
      controller.devfile.io/mount-path: /<DESIRED_MOUNT_PATH> # example - /projects/shared
    name: shared-workspace-volume
    labels:
      controller.devfile.io/mount-to-devworkspace: "true"
  spec:
    accessModes:
      - ReadWriteMany
    resources:
      requests:
        storage: 50Gi
    storageClassName: <STORAGE_CLASS_THAT_SUPPORTS_RWX>
```

## SMB/CIFS Share


