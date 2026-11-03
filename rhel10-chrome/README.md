```bash
if [ ! -d ${HOME}/.config/google-chrome ]
then
  mkdir -p ${HOME}/.config/google-chrome
  touch ${HOME}/.config/google-chrome/'First Run'
fi
rm -f ${HOME}/.config/google-chrome/Singleton{Cookie,Lock,Socket}

if [ ! -d ${HOME}/.vnc ]
then
  mkdir ${HOME}/.vnc
  touch ${HOME}/.vnc/.de-was-selected
  (echo '#!/bin/sh';echo 'unset SESSION_MANAGER';echo 'unset DBUS_SESSION_BUS_ADDRESS';echo 'echo starting Xvnc') > ${HOME}/.vnc/xstartup
  chmod +x ${HOME}/.vnc/xstartup
fi
cat << EOF > ${HOME}/.vnc/kasmvnc.yaml
network:
  websocket_port: 8444
  interface: 0.0.0.0
  protocol: http
  ssl:
    require_ssl: false
  use_ipv4: true
  use_ipv6: false
user_session:
  session_type: exclusive
  concurrent_connections_prompt: false
logging:
  log_writer_name: all
  log_dest: logfile
  level: 30
desktop:
  resolution:
    width: 1280
    height: 1024
  allow_resize: true
  pixel_depth: 24
EOF
VNC_PASSWD=nopasswd
echo -e "${VNC_PASSWD}\n${VNC_PASSWD}\n" | vncpasswd -w -r -u user ${HOME}/.kasmpasswd
/usr/bin/vncserver :0 -disableBasicAuth

export $(dbus-launch)
/usr/bin/google-chrome --display=:0 --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-plugins --disable-plugins-discovery --disable-notifications --disable-sync --mute-audio --dns-prefetch-disable --noremote --start-maximized > /tmp/chrome.out 2>&1 &
```

```yaml
kind: List
apiVersion: v1
items:
# Create a proxy service account and ensure it will use the route "proxy"
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: proxy
    annotations:
      serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"proxy"}}'
# Create a secure connection to the proxy via a route
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    name: proxy
  spec:
    to:
      kind: Service
      name: proxy
    tls:
      termination: Reencrypt
- apiVersion: v1
  kind: Service
  metadata:
    name: proxy
    annotations:
      service.alpha.openshift.io/serving-cert-secret-name: proxy-tls
  spec:
    ports:
    - name: proxy
      port: 443
      targetPort: 8443
    selector:
      app: proxy
# Launch a proxy as a sidecar
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: proxy
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: proxy
    template:
      metadata:
        labels:
          app: proxy
      spec:
        serviceAccountName: proxy
        containers:
        - name: oauth-proxy
          image: image-registry.openshift-image-registry.svc:5000/openshift/oauth-proxy:v4.4
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8443
            name: public
          args:
          - --https-address=:8443
          - --provider=openshift
          - --openshift-service-account=proxy
          - --upstream=http://localhost:8080
          - --tls-cert=/etc/tls/private/tls.crt
          - --tls-key=/etc/tls/private/tls.key
          - --cookie-secret=SECRET
          volumeMounts:
          - mountPath: /etc/tls/private
            name: proxy-tls

        - name: app
          image: openshift/hello-openshift:latest
        volumes:
        - name: proxy-tls
          secret:
            secretName: proxy-tls
```


      - attributes:
          container-overrides:
            volumeMounts:
              - mountPath: /etc/tls/private
                name: proxy-tls
          pod-overrides:
            spec:
              volumes:
                - name: proxy-tls
                  secret:
                    secretName: proxy-tls
        container:
          args:
            - '--https-address=:9443'
            - '--provider=openshift'
            - '--openshift-service-account=workspaced50a06d73e854abd-sa'
            - '--upstream=http://localhost:8444'
            - '--tls-cert=/etc/tls/private/tls.crt'
            - '--tls-key=/etc/tls/private/tls.key'
            - '--cookie-secret=SECRET'
          endpoints:
            - exposure: public
              name: proxy
              protocol: https
              targetPort: 9443
          env:
            - name: HOST_USERS
              value: 'false'
          image: 'image-registry.openshift-image-registry.svc:5000/openshift/oauth-proxy:v4.4'
          sourceMapping: /projects
        name: oauth-proxy

## Devfile
```yaml
schemaVersion: 2.3.0
metadata:
  name: devspaces-chrome
components:
- name: dev-tools
  container:
    image: quay.io/cgruver0/che/chrome-devspaces-ubi10:latest
    memoryLimit: 6Gi
    cpuLimit: 1000m
    mountSources: true
    env:
    - name: SHELL
      value: "/bin/zsh"
    endpoints:
      - exposure: public
        name: kasmvnc
        targetPort: 8444
        protocol: https
- name: oauth-proxy
  attributes:
    pod-overrides:
      metadata:
        labels:
          app: proxy
      spec:
        volumes:
        - name: proxy-tls
          secret:
            secretName: proxy-tls
    container-overrides: 
      volumeMounts:
        - mountPath: /etc/tls/private
          name: proxy-tls
  container:
    image: image-registry.openshift-image-registry.svc:5000/openshift/oauth-proxy:v4.4
    args:
    - --https-address=:8443
    - --provider=openshift
    - --upstream=http://localhost:8444
    - --tls-cert=/etc/tls/private/tls.crt
    - --tls-key=/etc/tls/private/tls.key
    - --cookie-secret=SECRET
    endpoints:
      - exposure: none
        name: proxy
        protocol: https
        targetPort: 8443
- name: oauth-route
  openshift:
    deployByDefault: true
    inlined: |
      apiVersion: route.openshift.io/v1
      kind: Route
      metadata:
        name: proxy
      spec:
        to:
          kind: Service
          name: proxy
        tls:
          termination: Reencrypt
- name: oauth-service
  openshift:
    deployByDefault: true
    inlined: |
      apiVersion: v1
      kind: Service
      metadata:
        name: proxy
        annotations:
          service.alpha.openshift.io/serving-cert-secret-name: proxy-tls
      spec:
        ports:
        - name: proxy
          port: 443
          targetPort: 8443
        selector:
          app: proxy
- volume:
    size: 20Gi
  name: projects
```

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: proxy
spec:
  to:
    kind: Service
    name: proxy
  tls:
    termination: Passthrough
---
apiVersion: v1
kind: Service
metadata:
  name: proxy
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: proxy-tls
spec:
  ports:
  - name: proxy
    port: 443
    targetPort: 8443
  selector:
    app: proxy
```


# Secret metadata:

```yaml
metadata:
  annotations:
    controller.devfile.io/mount-as: subpath
    controller.devfile.io/mount-path: /etc/tls/private
  labels:
    controller.devfile.io/mount-to-devworkspace: 'true'
    controller.devfile.io/watch-secret: 'true'
```

- --openshift-service-account=workspaced50a06d73e854abd-sa



{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[0].env[16]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"8347fd61-e82c-43e2-af36-d574d74291ff"}
{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[1].env[9]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"8347fd61-e82c-43e2-af36-d574d74291ff"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Updated object","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","kind":"v1.Deployment","name":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"v1.Deployment workspace8c4aefc8b00443e7 is not ready: Updated object","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Waiting on deployment to be ready","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Reconciling Workspace","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7","resolvedConfig":"workspace.progressTimeout=300s,workspace.ignoredUnrecoverableEvents=FailedScheduling,workspace.containerSecurityContext is set,workspace.podAnnotations is set,workspace.cleanupCronJob.enable=true,workspace.hostUsers=false,workspace.overrides.restrictedContainerOverrideFields=[],workspace.overrides.restrictedPodOverrideFields=[]"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"v1.Deployment workspace8c4aefc8b00443e7 is not ready: Need to retry","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Waiting on deployment to be ready","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Reconciling Workspace","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7","resolvedConfig":"workspace.progressTimeout=300s,workspace.ignoredUnrecoverableEvents=FailedScheduling,workspace.containerSecurityContext is set,workspace.podAnnotations is set,workspace.cleanupCronJob.enable=true,workspace.hostUsers=false,workspace.overrides.restrictedContainerOverrideFields=[],workspace.overrides.restrictedPodOverrideFields=[]"}
{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[0].env[16]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"78e45a5e-4087-4baa-b076-33406c15efa1"}
{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[1].env[9]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"78e45a5e-4087-4baa-b076-33406c15efa1"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"v1.Deployment workspace8c4aefc8b00443e7 is not ready: Need to retry","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Waiting on deployment to be ready","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Reconciling Workspace","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7","resolvedConfig":"workspace.progressTimeout=300s,workspace.ignoredUnrecoverableEvents=FailedScheduling,workspace.containerSecurityContext is set,workspace.podAnnotations is set,workspace.cleanupCronJob.enable=true,workspace.hostUsers=false,workspace.overrides.restrictedContainerOverrideFields=[],workspace.overrides.restrictedPodOverrideFields=[]"}
{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[0].env[16]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"ad7d846f-062f-4a57-9c0b-9eb51424c19b"}
{"level":"info","ts":"2026-11-03T20:14:27Z","msg":"spec.template.spec.containers[1].env[9]: hides previous definition of \"HOST_USERS\", which may be dropped when using apply","controller":"devworkspace","controllerGroup":"workspace.devfile.io","controllerKind":"DevWorkspace","DevWorkspace":{"name":"devspaces-chrome","namespace":"cgruver-devspaces"},"namespace":"cgruver-devspaces","name":"devspaces-chrome","reconcileID":"ad7d846f-062f-4a57-9c0b-9eb51424c19b"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Updated object","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","kind":"v1.Deployment","name":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"v1.Deployment workspace8c4aefc8b00443e7 is not ready: Updated object","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Waiting on deployment to be ready","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"Reconciling Workspace","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7","resolvedConfig":"workspace.progressTimeout=300s,workspace.ignoredUnrecoverableEvents=FailedScheduling,workspace.containerSecurityContext is set,workspace.podAnnotations is set,workspace.cleanupCronJob.enable=true,workspace.hostUsers=false,workspace.overrides.restrictedContainerOverrideFields=[],workspace.overrides.restrictedPodOverrideFields=[]"}
{"level":"info","ts":"2026-11-03T20:14:27Z","logger":"controllers.DevWorkspace","msg":"v1.Deployment workspace8c4aefc8b00443e7 is not ready: Need to retry","Request.Namespace":"cgruver-devspaces","Request.Name":"devspaces-chrome","devworkspace_id":"workspace8c4aefc8b00443e7"}
