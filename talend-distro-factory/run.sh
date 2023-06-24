#!/usr/bin/env bash

[ "${TALEND_DISTRO_RUN_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_RUN_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_run() {

  # parameters
  local image_tag
  local container_name
  local volume_name

  local args

  # declare and initialize inherited parameters and settings
  local -r image_name="${image_name:-${TALEND_DISTRO_IMAGE_NAME:-${talend_distro_image_name_default:-talend_distro}}}"
  local -r talend_version="${talend_version:-{$TALEND_DISTRO_TALEND_VERSION:-${talend_distro_talend_version_default:-8.0.1}}}"

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_create_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro [options...] [arguments...]" ''
      msg -- 'Options:'
      param   image_tag            -i    --image        init:="talend-distro"
      param   container_name       -c    --container    init:=""
      param   volume_name          -v    --volume       init:=""
      # shellcheck disable=SC1083
      disp    :usage               -h                                                    -- "help summary"
      disp    :usage                     --help                                          -- "help details"
    }

    eval "$(getoptions "${parser_name}_def" "${parser_name}")"
  fi

  # call the function arg parser
  "${parser_name}" "${@}"

  # reset the stack $@ variable to the positional arguments
  eval "set -- ${args}"

  # calculate derived parameters
  container_name="${container_name:-${TALEND_DISTRO_CONTAINER_NAME:-${image_name}-${talend_version}}}"

  # make parameters immutable
  readonly image_name talend_version container_name

  # configuration settings can be overridden by shell or environment variables

  # calculate derived settings
  local -r image_tag="${image_name}:${talend_version}"

  # body of the function

  infoVar talend_version
  infoVar image_name
  infoVar container_name
  infoVar image_tag

  docker create --name  "${container_name}" "${image_tag}"

  return 0
}

