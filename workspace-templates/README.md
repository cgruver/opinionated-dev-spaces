
```bash
oc project workspace-templates
touch header.yaml
yq -e '.schemaVersion = "2.3.0"' -i header.yaml
yq -e '.metadata.name = "basic-workspace"' -i header.yaml
oc get DevWorkspaceTemplate basic-workspace -o yaml | yq '.spec' > basic-workspace.yaml
oc get DevWorkspaceTemplate postgres-15 -o yaml | yq -e '.spec' > postgres-15.yaml
oc get DevWorkspaceTemplate inject-oc-cli -o yaml | yq -e '.spec' > inject-oc-cli.yaml
yq eval-all '. as $item ireduce ({}; . *+ $item)' header.yaml basic-workspace.yaml postgres-15.yaml inject-oc-cli.yaml > devfile-test.yaml
```
