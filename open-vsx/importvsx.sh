#!/usr/bin/env bash

function downloadExtension() {

  local url=${1}
  local fileName=${2}
  local namespace=${3}

  echo "Downloading: ${url}"
  curl -sL "${url}" -o "${WORK_DIR}/${fileName}"
  if [[ ${OFF_LINE} == "true" ]]
  then
    echo "${namespace}" >> ${WORK_DIR}/tmp-namespace.list
    echo "${fileName}" >> ${WORK_DIR}/bundle.list
  else
    ovsx create-namespace ${namespace}
    ovsx publish --skip-duplicate ${WORK_DIR}/${fileName}
  fi
}

function checkVersionCompatibility() {
  local min_ver=${1}

  min_ver_x=$(echo ${min_ver} | cut -d"." -f1)
  min_ver_y=$(echo ${min_ver} | cut -d"." -f2)
  min_ver_z=$(echo ${min_ver} | cut -d"." -f3)

  vscode_ver_x=$(echo ${VSCODE_VERSION} | cut -d"." -f1)
  vscode_ver_y=$(echo ${VSCODE_VERSION} | cut -d"." -f2)
  vscode_ver_z=$(echo ${VSCODE_VERSION} | cut -d"." -f3)

  if [[ ${vscode_ver_x} -gt ${min_ver_x} ]]
  then
    echo "true"
    return 0
  elif [[ ${vscode_ver_x} -eq ${min_ver_x} ]]
  then
    if [[ ${vscode_ver_y} -gt ${min_ver_y} ]]
    then
      echo "true"
      return 0
    elif [[ ${vscode_ver_y} -eq ${min_ver_y} ]]
    then
      if [[ ${vscode_ver_z} -ge ${min_ver_z} ]]
      echo "true"
      return 0
    fi
  fi
  echo "false"
}

function getCompatibleRelease() {
  local ext_id=${1}
  local num_versions=0
  local index=0
  local ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&includeAllVersions=true&targetPlatform=${ARCH}&size=500&offset=0" -H 'accept: application/json' | jq '.extensions[] | select(.preRelease==false)')

  num_versions=$(echo ${ext_data} | jq -r -s '. | length')
  if [[ ${num_versions} -eq 0 ]]
  then
    ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&includeAllVersions=true&targetPlatform=universal&size=500&offset=0" -H 'accept: application/json' | jq '.extensions[] | select(.preRelease==false)')
    num_versions=$(echo ${ext_data} | jq -r -s '. | length')
    if [[ ${num_versions} -eq 0 ]]
    then
      echo "not-found"
      return 1
    fi
  fi
  while [[ ${index} -lt ${num_versions} ]]
  do
    vscode_min_ver=$(echo ${ext_data} | jq -r -s ".[${index}] | .engines.vscode" | sed 's/\^//g')
    compatible=$(checkVersionCompatibility ${vscode_min_ver})
    if [[ ${compatible} == "true" ]]
    then
      ext_compat=$(echo ${ext_data} | jq -r -s ".[${index}]")
      break
    fi
    index=$(( ${index} + 1 ))
  done
  echo ${ext_compat}
}

function fetchDependencies() {
  local ext_release=${1}
  local index=0

  num_deps=$(echo "${ext_release}" | jq '.dependencies | length')
  while [[ ${index} -lt ${num_deps} ]]
  do
    dep_namespace=$(echo "${ext_release}" | jq ".dependencies.[${index}].namespace")
    dep_extension=$(echo "${ext_release}" | jq ".dependencies.[${index}].extension")
    dep_id="${dep_namespace}.${dep_extension}"
    dep_release=$(getCompatibleRelease ${dep_id})
    dep_url=$(echo "${dep_release}" | jq '.files.download')
    downloadExtension ${dep_url} ${dep_id//./-}.vsix $(echo ${dep_id} | cut -d"." -f1)
    index=$(( ${index} + 1 ))
  done
}

function download() {
  WORK_DIR=$(mktemp -d)
  VSCODE_VERSION=$(jq ".vscode-version" ${EXTENSION_FILE})
  ARCH=$(jq '.architecture' ${EXTENSION_FILE})
  local index=0
  local num_ext=$(jq '.extensions | length' ${EXTENSION_FILE})

  while [[ ${index} -lt ${num_ext} ]]
  do
    ext_id=$(jq ".extensions.[${index}].id" ${EXTENSION_FILE})
    has_url=$(jq ".extensions.[${index}] | has(\"url\")" ${EXTENSION_FILE})
    if [[ ${has_url} == "true" ]]
    then
      ext_url=$(yq e ".extensions.[${index}].url" ${EXTENSION_FILE})
      downloadExtension ${ext_url} ${ext_id//./-}.vsix $(echo ${ext_id} | cut -d"." -f1)
      continue
    fi
    has_version=$(jq ".extensions.[${index}] | has(\"version\")" ${EXTENSION_FILE})
    if [[ ${has_version} == "true" ]]
    then
      ext_version=$(jq ".extensions.[${index}].version" ${EXTENSION_FILE})
      ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=devsense.composer-php-vscode&targetPlatform=${ARCH}&extensionVersion=1.70.18915&offset=0" -H 'accept: application/json' | jq '.extensions[]')
      let result=$(echo ${ext_data} | jq -r -s '. | length')
      if [[ ${result} -eq 0 ]]
      then
        ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=devsense.composer-php-vscode&targetPlatform=universal&extensionVersion=1.70.18915&offset=0" -H 'accept: application/json' | jq '.extensions[]')
        let result=$(echo ${ext_data} | jq -r -s '. | length')
        if [[ ${result} -eq 0 ]]
          echo "ERROR: Extension ${ext_id} not found"
          continue
        fi
      fi
      ext_release=$(echo ${ext_data} | jq -r -s ".[0]")
    else
      ext_release=$(getCompatibleRelease ${ext_id})
    fi
    fetchDependencies ${ext_release}
    ext_url=$(echo "${ext_release}" | jq '.files.download')
    downloadExtension ${ext_url} ${ext_id//./-}.vsix $(echo ${ext_id} | cut -d"." -f1)
    index=$(( ${index} + 1 ))
  done
  if [[ ${OFF_LINE} == "true" ]]
  then
    BUNDLE_NAME="openvsx-bundle-$(date +%m%d%Y%H%M%S).tar"
    cat ${WORK_DIR}/tmp-namespace.list | sort -u > ${WORK_DIR}/namespace.list
    rm ${WORK_DIR}/tmp-namespace.list
    tar -cvf ${BUNDLE_NAME} -C ${WORK_DIR} .
    echo "Extension Bundle Created at: ./${BUNDLE_NAME}"
  fi
  rm -rf ${WORK_DIR}
}

function upload() {

  WORK_DIR=$(mktemp -d)
  tar -xvf ${BUNDLE_NAME} -C ${WORK_DIR}
  for namespace in $(cat ${WORK_DIR}/namespace.list)
  do
    ovsx create-namespace ${namespace}
  done 
  for vsix in $(cat ${WORK_DIR}/bundle.list)
  do
    ovsx publish --skip-duplicate ${WORK_DIR}/${vsix}
  done
  rm -rf ${WORK_DIR}

}

for i in "$@"
do
  case $i in
    -d|--download)
      DOWNLOAD=true
    ;;
    -u|--upload)
      UPLOAD=true
    ;;
    -o|--offline)
      OFF_LINE=true
    ;;
    -f=*|--file=*)
      EXTENSION_FILE="${i#*=}"
    ;;
    -b=*|--bundle=*)
      BUNDLE_NAME="${i#*=}"
    ;;
    --help)
      printHelp
    ;;
  esac
done

if [[ ${DOWNLOAD} == "true" ]]
then
  download
elif [[ ${UPLOAD} == "true" ]]
then
  upload
fi
