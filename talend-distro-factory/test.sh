#!/usr/bin/env bash

[ "${TALEND_DISTRO_TEST_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_TEST_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_test() {

  local args

  # declare and initialize inherited parameters
  # shellcheck disable=SC2154
  eval "${talend_distro_init_cmd}"

  # declare parameters
  local container
  local volume

  # initialize parameters
  local talend_distro_run_init_cmd
  define talend_distro_run_init_cmd <<"__EOF__"
    container="${container:-${TALEND_DISTRO_CONTAINER:-${talend_distro_container_default:-talend-distro}}}"
    volume="${volume:-${TALEND_DISTRO_VOLUME:-${talend_distro_volume_default:-talend-${talend_version}}}}"
__EOF__
  readonly talend_distro_run_init_cmd
  eval "${talend_distro_run_init_cmd}"


  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_test_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro_test [options...] [arguments...]" ''
      msg -- 'Options:'
      param   talend_version       -v    --talend_version   init:="${talend_version}"  pattern:"8.0.1 | 7.3.1"
      param   container            -c    --container        init:="${container}"
      param   volume                     --volume           init:="${volume}"
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
  required talend_version
  readonly talend_version

  # make parameters immutable
  required container volume
  readonly container volume

  # configuration settings can be overridden by shell or environment variables
  local mount_dir="${mount_dir:-${TALEND_DISTRO_MOUNT_DIR:-${talend_distro_mount_dir_default:-/talend/downloads}}}"

  # calculate derived settings
  local -r container_name="${container}-test-${talend_version}"

  # body of the function

  infoVar talend_version
  infoVar container_name
  infoVar volume

  docker run --name "${container_name}" -v "${volume}:${mount_dir}" --rm busybox ls "${mount_dir}"

  return 0
}
