#!/usr/bin/env bash

[ "${TALEND_DISTRO_RUN_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_RUN_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_run() {

  local args

  # declare and initialize inherited parameters and settings
  local talend_version="${talend_version:-${TALEND_DISTRO_TALEND_VERSION:-${talend_distro_talend_version_default:-8.0.1}}}"
  local factory_image="${factory_image:-${TALEND_DISTRO_FACTORY_IMAGE:-${talend_distro_factory_image_default:-talend-distro}}}"
  local factory_tag="${factory_tag:-${TALEND_DISTRO_FACTORY_TAG:-${talend_distro_factory_tag:-${talend_version}}}}"

  # declare parameters
  local container
  local volume

  # initialize parameters
  container="${container:-${TALEND_DISTRO_CONTAINER:-${talend_distro_container_default:-talend-distro}}}"
  volume="${volume:-${TALEND_DISTRO_VOLUME:-${talend_distro_volume_default:-talend-${talend_version}}}}"

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_run_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro_run [options...] [arguments...]" ''
      msg -- 'Options:'
      param   talend_version       -v    --talend_version   init:="${talend_version}"  pattern:"8.0.1 | 7.3.1"
      param   factory_image        -f    --factory_image    init:="${factory_image}"
      param   factory_tag          -t    --factory_tag      init:="${factory_tag}"
      param   container            -c    --container        init:="${container}"
      param   volume               -v    --volume           init:="${volume}"
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

  # make inherited parameters immutable
  required talend_version factory_image factory_tag
  readonly talend_version factory_image factory_tag

  # make parameters immutable
  required container volume
  readonly container volume

  # configuration settings can be overridden by shell or environment variables

  # calculate derived settings
  local -r container_name="${container}-${talend_version}"
  local -r image_tag="${factory_image}:${factory_tag}"

  # body of the function

  infoVar talend_version
  infoVar factory_image
  infoVar factory_tag
  infoVar container_name
  infoVar volume

  docker run --name "${container_name}" -v "${volume}":/talend/downloads "${image_tag}"

  return 0
}

