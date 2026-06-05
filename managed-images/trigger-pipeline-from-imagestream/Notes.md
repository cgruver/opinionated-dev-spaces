

find . -type f -name "*.yaml"

```bash
base_image=$(echo "${BUILD}" | jq -j '.spec.triggeredBy[0].imageChangeBuild.imageID')
for image in $(find images -type f -name "*.yaml")
do
  from_image=$(yq e ".from" ${image})
  echo $from_image
done
```
