#!/usr/bin/env bash

[ "${TALEND_DISTRO_BUILD_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_BUILD_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_build() {

  # parameters
  local builder_image
  local builder_image_version
  local credentials
  local manifest

  local args

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_build_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro [options...] [arguments...]" ''
      msg -- 'Options:'
      param   builder_image          -i  --builder_image          init:="alpine"
      param   builder_image_version  -v  --builder_image_version  init:="3.18.0"
      param   credentials            -c  --credentials            init:="talend.credentials"
      param   manifest               -m  --manifest               init:="talend.manifest"
      # shellcheck disable=SC1083
      disp    :usage                 -h                                                    -- "help summary"
      disp    :usage                     --help                                            -- "help details"
    }

    eval "$(getoptions "${parser_name}_def" "${parser_name}")"
  fi

  # call the function arg parser
  "${parser_name}" "${@}"

  # reset the stack $@ variable to the positional arguments
  eval "set -- ${args}"

  # make parameters immutable
  readonly builder_image builder_image_version credentials manifest

  # configuration settings can be overridden by shell or environment variables
  local -r talend_version="${talend_version:-${TALEND_VERSION:-8.0.1}}"
  local -r image_name="${image_name:-${TALEND_DISTRO_IMAGE_NAME:-talend-distro}}"

  # calculate derived settings
  local -r image_tag="${image_name}:${talend_version}"

  # body of the function

  infoVar talend_version
  infoVar image_name
  infoVar image_tag
  infoVar builder_image
  infoVar builder_image_version
  infoVar credentials
  infoVar manifest

  docker buildx build \
    --no-cache \
    --build-arg builder_image="${builder_image}" \
    --build-arg builder_image_version="${builder_image_version}" \
    --build-arg talend_version="${talend_version}" \
    --build-arg talend_manifest="${manifest}" \
    --secret id=talend,src="${credentials}" \
    -t "${image_tag}" \
    .

  return 0
}
