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

# shellcheck source=create.sh
source "create.sh"

function talend_distro() {

  # parameters
  local talend_version
  local image_name

  # helper variable
  local args

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro [options...] [arguments...]" ''
      msg -- 'Options:'
      # shellcheck disable=SC1083
      param   talend_version       -v    --talend_version    init:="8.0.1" pattern:"8.0.1 | 7.3.1"
      param   image_name           -i    --image_name        init:="talend-distro"
      disp    :usage               -h           -- "help summary"
      disp    :talend_distro_help        --help -- "help details"
      msg -- '' 'Commands'
      cmd     build                             -- "build the Talend downloads data container image"
      cmd     create                            -- "create an instance of the Talend downloads data container"
    }

    eval "$(getoptions "${parser_name}_def" "${parser_name}")"
  fi

  # call the function arg parser
  "${parser_name}" "${@}"

  # reset the stack $@ variable to the positional arguments
  eval "set -- ${args}"

  # make parameters immutable
  readonly talend_version image_name

  # configuration settings can be overrident by shell or environment variables

  # calculate derived settings
  local -r image_tag="${image_name}:${talend_version}"

  # body of the function

  infoVar talend_version
  infoVar image_name
  infoVar image_tag

  if [ $# -gt 0 ]; then
    local cmd=$1
    case "${cmd}" in
      build)
        shift
        talend_distro_build "$@"
        return $?
        ;;
      create)
        shift
        talend_distro_create "$@"
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


function talend_distro_help() {
  local usage
  define usage <<EOF
Tools to download Talend subscription binary artifacts.

Usage:
    talend-distro [options] [ command ] [ args ]
    options : [ -v -i ]
    command : [ config | build | create | test ]
    args : see individual commands

Options:

    -v talend_version
      default = 8.0.1
      The version of Talend software to be downloaded.
      The version will be used as the tag for the image.

    -i image_name
      default = talend-distro
      The name of the data container image to be created.
Commands:

    config: initialize talend-distro configuration settings.

    build: builds a docker data container image to hold Talend distribution artifacts.

    create: instantiate an instance of the Talend distribution data container

    test: do a quick test of an instance of the Talend distribution data container.

Configuration:
    These configuration settings are initialized based on the following order of precedence:

    1.  Commandline arguments (for parameters only)
    2.  Shell Variables
    3.  Environment Variables
    4.  hard-coded defaults.

    base_builder_image
      default = alpine
      The image used as the builder during the docker multistage build.
      The final stage image is always scratch.
    base_builder_image_version
      default = 3.18.0
      The tag of the build image.
EOF
    echo "${usage}"
}
