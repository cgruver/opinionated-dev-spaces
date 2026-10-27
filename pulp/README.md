

```bash
echo "Waiting for Pulp Operator InstallPlan to exist..."
            
install_plan=""
until [[ ${install_plan} != "" ]]
do
  oc get installplan -n pulp
  install_plan=$(oc get installplan  -n pulp | grep "pulp-operator" | grep false | cut -d" " -f1)
  if [[ ${install_plan} == "" ]]
  then
    sleep 15
  fi
done
oc patch installplan ${install_plan} --type merge --patch '{"spec":{"approved":true }}'
echo "Pulp Operator InstallPlan Approved"

echo "Waiting for Pulp CSV to succeed in ${NS}..."
until CSV=$(oc get csv  -n pulp --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep pulp-operator | head -1) && \
      [ -n "${CSV}" ] && \
      [ "$(oc get csv ${CSV}  -n pulp -o jsonpath='{.status.phase}' 2>/dev/null)" = "Succeeded" ]; do
  echo "  ...CSV not ready yet"
  sleep 10
done
echo "CSV ${CSV} succeeded."

until [[ $(oc get deployment pulp-operator-controller-manager -n pulp -o jsonpath='{.status.readyReplicas}') -eq 1 ]]
do
  echo "Waiting for pulp-operator-operator deployment..."
  sleep 5
done
echo "Operator is ready."
```

```bash
python3 -m venv ${HOME}/.venv
. ${HOME}/.venv/bin/activate
pip install pulp-cli
pip install pulp-cli-maven

mkdir -p ${HOME}/.config/pulp
cat << EOF > ${HOME}/.config/pulp/cli.toml
[cli]
base_url = "http://pulp-api-svc.pulp.svc.cluster.local:24817"
api_root = "/pulp/"
domain = "default"
headers = []
verify_ssl = false
format = "json"
dry_run = false
timeout = 0
verbose = 1
EOF

pulp --username admin --password $(oc get secret pulp-admin-password -n pulp -o jsonpath="{.data.password}" | base64 --decode) maven remote create --name maven-central --url https://repo1.maven.org/maven2/
pulp --username admin --password $(oc get secret pulp-admin-password -n pulp -o jsonpath="{.data.password}" | base64 --decode) maven repository create --name maven-central --remote maven-central
pulp --username admin --password $(oc get secret pulp-admin-password -n pulp -o jsonpath="{.data.password}" | base64 --decode) maven distribution create --name maven-central --remote maven-central --repository maven-central --base-path maven-central
```

```xml
<settings>
  <mirrors>
    <mirror>
      <id>pulp-maven-central</id>
      <name>Local Maven Central mirror </name>
      <url>http://pulp-content-svc.pulp.svc.cluster.local:24816/pulp/content/maven-central/</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```
