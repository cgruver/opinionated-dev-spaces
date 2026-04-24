# che-openvsx-registry

Self Hosted instance of Open VSX for disconnected OpenShift installations using Eclipse Che (OpenShift Dev Spaces)

### Deploy Open VSX Registry

```bash
oc apply -f deploy-openvsx.yaml
```

### Wait for the deployment to complete

```bash
oc wait --for=condition=Available deployment/open-vsx-server -n che-openvsx --timeout=180s
```

### Enable Eclipse Che / OpenShift Dev Spaces to use the hosted OpenVSX instance
```bash
OVSX_URL=https://$(oc get route open-vsx-server -n che-openvsx -o jsonpath={.spec.host})

oc patch CheCluster devspaces -n devspaces --type merge --patch "{\"spec\":{\"components\":{\"pluginRegistry\":{\"openVSXURL\":\"${OVSX_URL}\"}}}}"
```

### Create an Access Token to be used for importing extensions

Execute the following commands in a terminal on the Postgres Pod

```bash
PG_POD=$(oc get pods --selector name=open-vsx-pg -n che-openvsx -o name)

oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"INSERT INTO user_data (id, login_name) VALUES (1001, 'eclipse-che');\" && \
  psql -d openvsx -c \"INSERT INTO personal_access_token (id, user_data, value, active, created_timestamp, accessed_timestamp, description) VALUES (1001, 1001, 'eclipse_che_token', false, current_timestamp, current_timestamp, 'extensions');\" && \
  psql -d openvsx -c \"UPDATE user_data SET role='admin' WHERE user_data.login_name='eclipse-che';\""
```

## Prepare For Extension Import

### Enable Access Token

```bash
PG_POD=$(oc get pods --selector name=open-vsx-pg -n che-openvsx -o name)
oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"UPDATE personal_access_token SET active = true;\""
```
### Install OpenVSX CLI

```bash
npm install --global ovsx
```

### Set `ovsx` Environment

```bash
export OVSX_REGISTRY_URL=https://$(oc get route open-vsx-server -n che-openvsx -o jsonpath={.spec.host})
export OVSX_PAT=eclipse_che_token
export NODE_TLS_REJECT_UNAUTHORIZED='0'
```

### Download Extensions

Modify `extension-list.yaml` to suit your needs, or create your own file with a list of extensions following the example in `extension-list.yaml`

```bash
./offline-extensions.sh -d -f=extension-list.yaml 
```

Note the name of the bundle that is created.

### Import Extensions

```bash
./offline-extensions.sh -u -b=/path/to/the/openvsx-bundle-****.tar
```

### Disable Access Token

Execute the following command in a terminal on the Postgres Pod

```bash
oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"UPDATE personal_access_token SET active = false;\""
```