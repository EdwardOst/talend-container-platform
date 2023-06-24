#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [ "${1:-}" == "-h" ]; then
    declare usage="./test [<talend_version>]"
    echo "${usage}"
    exit
fi


# parameters

declare -r talend_version="${1:-8.0.1}"
declare -r image_name="${image_name:-talend_distro}"
declare -r manifest="short.manifest"
declare -r credentials="talend.credentials"

#docker buildx build -t ${image_name}:${talend_version} --no-cache --build-arg talend_manifest="${manifest}" --secret id=talend,src="${credentials}" .

docker run --name ${image_name}-${talend_version} --rm -it "${image_name}:${talend_version}" ls