#!/usr/bin/env bash

set -e

QUERY_RESULT_SIZE=600

function createNamespace() {
  local namespace=${1}
  local check_namespace=$(curl -sLS "${OVSX_REGISTRY_URL}/api/${namespace}" -H 'accept: application/json' | jq -c '. | has("error")')
  if [[ ${check_namespace} == "true" ]]
  then
    ovsx create-namespace ${namespace}
  fi
}

function publishExtension() {
  local vsix_file=${1}
  ovsx publish --skip-duplicate ${WORK_DIR}/${vsix_file}
}

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
    createNamespace ${namespace}
    publishExtension ${fileName}
  fi
}

# Interesting note, I had help with this function from Nemotron Super running on an ASUS GX10 + Kilo Code
function checkVersionCompatibility() {
  local min_ver=${1}
  
  # Convert version strings to arrays, handling missing parts
  IFS='.' read -ra MIN_VER_PARTS <<< "${min_ver}"
  IFS='.' read -ra VSCODE_VER_PARTS <<< "${VSCODE_VERSION}"
  
  # Pad arrays to at least 3 elements with zeros
  while [[ ${#MIN_VER_PARTS[@]} -lt 3 ]]; do
    MIN_VER_PARTS+=("0")
  done
  while [[ ${#VSCODE_VER_PARTS[@]} -lt 3 ]]; do
    VSCODE_VER_PARTS+=("0")
  done
  
  # Compare each part numerically
  if [[ ${VSCODE_VER_PARTS[0]} -gt ${MIN_VER_PARTS[0]} ]]; then
    echo "true"
    return 0
  elif [[ ${VSCODE_VER_PARTS[0]} -eq ${MIN_VER_PARTS[0]} ]]; then
    if [[ ${VSCODE_VER_PARTS[1]} -gt ${MIN_VER_PARTS[1]} ]]; then
      echo "true"
      return 0
    elif [[ ${VSCODE_VER_PARTS[1]} -eq ${MIN_VER_PARTS[1]} ]]; then
      if [[ ${VSCODE_VER_PARTS[2]} -ge ${MIN_VER_PARTS[2]} ]]; then
        echo "true"
        return 0
      fi
    fi
  fi
  echo "false"
}

# My original function that Kilo + Nemotron improved
# function checkVersionCompatibility() {
#   local min_ver=${1}

#   min_ver_x=$(echo ${min_ver} | cut -d"." -f1)
#   min_ver_y=$(echo ${min_ver} | cut -d"." -f2)
#   min_ver_z=$(echo ${min_ver} | cut -d"." -f3)

#   vscode_ver_x=$(echo ${VSCODE_VERSION} | cut -d"." -f1)
#   vscode_ver_y=$(echo ${VSCODE_VERSION} | cut -d"." -f2)
#   vscode_ver_z=$(echo ${VSCODE_VERSION} | cut -d"." -f3)

#   if [[ ${vscode_ver_x} -gt ${min_ver_x} ]]
#   then
#     echo "true"
#     return 0
#   elif [[ ${vscode_ver_x} -eq ${min_ver_x} ]]
#   then
#     if [[ ${vscode_ver_y} -gt ${min_ver_y} ]]
#     then
#       echo "true"
#       return 0
#     elif [[ ${vscode_ver_y} -eq ${min_ver_y} ]]
#     then
#       if [[ ${vscode_ver_z} -ge ${min_ver_z} ]]
#       then
#         echo "true"
#         return 0
#       fi
#     fi
#   fi
#   echo "false"
# }

function getCompatibleRelease() {
  local ext_id=${1}
  local results=0
  local index=0

  local ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&includeAllVersions=true&targetPlatform=${ARCH}&size=${QUERY_RESULT_SIZE}&offset=0" -H 'accept: application/json')
  results=$(echo "${ext_data}" | jq -r '.totalSize')
  if [[ ${results} -eq 0 ]]
  then
    ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&includeAllVersions=true&targetPlatform=universal&size=${QUERY_RESULT_SIZE}&offset=0" -H 'accept: application/json')
    results=$(echo "${ext_data}" | jq -r '.totalSize')
    if [[ ${results} -eq 0 ]]
    then
      echo "not-found"
      return 1
    fi
  fi
  ext_data=$(echo "${ext_data}" | jq -c '.extensions[] | select(.preRelease==false)')
  results=$(echo "${ext_data}" | jq -c -s '. | length')
  while [[ ${index} -lt ${results} ]]
  do
    vscode_min_ver=$(echo "${ext_data}" | jq -c -s ".[${index}]" | jq -r '.engines.vscode' | sed 's/\^//g')
    if [[ ${vscode_min_ver} == "*" ]]
    then
      ext_compat=$(echo "${ext_data}" | jq -c -s ".[${index}]")
      break
    fi
    # Handle common version specifiers by taking just the version number
    vscode_min_ver=$(echo ${vscode_min_ver} | sed -E 's/[<>=~^].*//')
    # If after stripping we have nothing, it was just a specifier like "^"
    if [[ -z ${vscode_min_ver} ]]; then
      vscode_min_ver="0.0.0"
    fi
    compatible=$(checkVersionCompatibility ${vscode_min_ver})
    if [[ ${compatible} == "true" ]]
    then
      ext_compat=$(echo "${ext_data}" | jq -c -s ".[${index}]")
      break
    fi
    index=$(( ${index} + 1 ))
  done
  echo "${ext_compat}"
}

function fetchDependencies() {
  local ext_release="${1}"
  local index=0

  num_deps=$(echo "${ext_release}" | jq '.dependencies | length')
  while [[ ${index} -lt ${num_deps} ]]
  do
    dep_namespace=$(echo "${ext_release}" | jq -r ".dependencies.[${index}].namespace")
    dep_extension=$(echo "${ext_release}" | jq -r ".dependencies.[${index}].extension")
    dep_id="${dep_namespace}.${dep_extension}"
    dep_release=$(getCompatibleRelease ${dep_id})
    dep_url=$(echo "${dep_release}" | jq -r '.files.download')
    downloadExtension ${dep_url} ${dep_id//./-}.vsix $(echo ${dep_id} | cut -d"." -f1)
    index=$(( ${index} + 1 ))
  done
}

function download() {
  WORK_DIR=$(mktemp -d)
  VSCODE_VERSION=$(jq -r ".vscode" ${EXTENSION_FILE})
  ARCH=$(jq -r '.architecture' ${EXTENSION_FILE})
  local index=0
  local num_ext=$(jq -r '.extensions | length' ${EXTENSION_FILE})
  local count=0

  while [[ ${index} -lt ${num_ext} ]]
  do
    ext_id=$(jq -r ".extensions.[${index}].id" ${EXTENSION_FILE})
    has_url=$(jq ".extensions.[${index}] | has(\"url\")" ${EXTENSION_FILE})
    if [[ ${has_url} == "true" ]]
    then
      ext_url=$(jq -r ".extensions.[${index}].url" ${EXTENSION_FILE})
      downloadExtension ${ext_url} ${ext_id//./-}.vsix $(echo ${ext_id} | cut -d"." -f1)
      continue
    fi
    has_version=$(jq ".extensions.[${index}] | has(\"version\")" ${EXTENSION_FILE})
    if [[ ${has_version} == "true" ]]
    then
      ext_version=$(jq -r ".extensions.[${index}].version" ${EXTENSION_FILE})
      ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&targetPlatform=${ARCH}&extensionVersion=${ext_version}&offset=0" -H 'accept: application/json')
      count=$(echo "${ext_data}" | jq -r '.totalSize')
      if [[ ${count} -eq 0 ]]
      then
        ext_data=$(curl -X GET "https://open-vsx.org/api/v2/-/query?extensionId=${ext_id}&targetPlatform=universal&extensionVersion=${ext_version}&offset=0" -H 'accept: application/json')
        count=$(echo "${ext_data}" | jq -s '. | length')
        if [[ ${count} -eq 0 ]]
        then
          echo "ERROR: Extension ${ext_id} not found"
          continue
        fi
      fi
      ext_release=$(echo "${ext_data}" | jq -c ".extensions.[0]")
    else
      ext_release=$(getCompatibleRelease ${ext_id})
    fi
    fetchDependencies "${ext_release}"
    ext_url=$(echo "${ext_release}" | jq -r '.files.download')
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
    createNamespace ${namespace}
  done 
  for vsix in $(cat ${WORK_DIR}/bundle.list)
  do
    publishExtension ${vsix}
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