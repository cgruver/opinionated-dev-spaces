oc project workspace-templates
oc get DevWorkspaceTemplate basic-workspace -o yaml | yq -e '.spec'