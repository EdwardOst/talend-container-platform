#!/usr/bin/env bash

[ "${TALEND_DISTRO_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

# shellcheck source=build.sh
source "build.sh"

# shellcheck source=run.sh
source "run.sh"

talend_distro() {

  # declare and initialize inherited parameters

  # declare and initialize parameters
  local talend_distro_init_cmd
  define talend_distro_init_cmd << "__EOF__"
    local talend_version="${talend_version:-${TALEND_DISTRO_TALEND_VERSION:-${talend_distro_talend_version_default:-8.0.1}}}"
    local factory_image="${factory_image:-${TALEND_DISTRO_FACTORY_IMAGE:-${talend_distro_factory_image_default:-talend-distro}}}"
    local factory_tag="${factory_tag:-${TALEND_DISTRO_FACTORY_TAG:-${talend_distro_factory_tag:-${talend_version}}}}"
__EOF__
  readonly talend_distro_init_cmd

  eval "${talend_distro_init_cmd}"

  # helper variables
  local args

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    talend_distro_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro [options...] [arguments...]" ''
      msg -- 'Options:'
      # shellcheck disable=SC1083
      param   talend_version       -v    --talend_version    init:="${talend_version}"    pattern:"8.0.1 | 7.3.1"
      param   factory_image        -f    --factory_image     init:="${factory_image}"
      param   factory_tag          -t    --factory_tag       init:="${factory_tag}"
      disp    :usage               -h           -- "help summary"
      disp    :talend_distro_help        --help -- "help details"
      msg -- '' 'Commands'
      cmd     build                             -- "build the Talend distro factory image"
      cmd     run                               -- "run a Talend distro factory container to create an instance of the Talend downloads volume"
      cmd     test                              -- "run a Talend distro factory container to downloading only sha256 to test connectivity"
    }

    eval "$(getoptions "${parser_name}_def" "${parser_name}")"
  fi

  # call the function arg parser
  "${parser_name}" "${@}"

  # reset the stack $@ variable to the positional arguments
  eval "set -- ${args}"

  # make inherited parameters immutable

  # make parameters immutable
  required talend_version factory_image factory_tag
  readonly talend_version factory_image factory_tag

  # configuration settings can be overrident by shell or environment variables

  # calculate derived settings

  # body of the function

  infoVar talend_version
  infoVar factory_image
  infoVar factory_tag

  if [ $# -gt 0 ]; then
    local cmd=$1
    case "${cmd}" in
      build)
        shift
        talend_distro_build "$@"
        return $?
        ;;
      run)
        shift
        talend_distro_run "$@"
        return $?
        ;;
      test)
        shift
        echo "****** talend_distro_test not enabled  *******"
#        talend_distro_test "$@"
        return $?
        ;;
      --) # no subcommand, arguments only
    esac
  fi

  echo "  -- arguments begin"
  local arg
  for arg in "${@}"; do
    if [[ ! "${arg}" == "--" ]]; then
      printf "    %s=%s\n" "${arg}" "${!arg}"
    fi
  done
  echo "  -- arguments end"

  return 0
}


talend_distro_help() {
  local usage
  define usage <<EOF
Tools to download Talend subscription binary artifacts.

Usage:
    talend-distro [options] [ command ] [ args ]
    options : [ -v -f ]
    command : [ build | run | test ]
    args : see individual commands

Options:

    -v    --talend_version
      default = 8.0.1
      The version of Talend software to be downloaded.

    -f --factory_image
      default = talend-distro
      The name of the factory image to be created.

    --factory_tag
      default = <talend_version>
      Docker tag of the factory image.

Commands:

    build: create a factory image for downloading Talend distribution artifacts

    run: run a factory container to create a Volume holding the Talend distribution artifacts.

    test: do a quick test downloading only sha256 files.

Configuration:
    These configuration settings are initialized based on the following order of precedence:

    1.  Commandline arguments
    2.  Shell variables
    3.  Environment variables
    4.  Shell default variables
    4.  hard-coded defaults.

EOF
    echo "${usage}"
}
