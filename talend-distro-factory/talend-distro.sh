#!/usr/bin/env bash

[ "${TALEND_DISTRO_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_FLAG=1

talend_distro_script_path=$(readlink -e "${BASH_SOURCE[0]}")
talend_distro_script_dir="${talend_distro_script_path%/*}"

talend_distro_util_path=$(readlink -e "${talend_distro_script_dir}/util/util.sh")
# shellcheck source=util/util.sh
source "${talend_distro_util_path}"

set -u

function talend_distro() {

  local help_flag=0
  talend_distro_parse_args "$@"
  # exit with success value if help was requested
  if [ "${help_flag}" -eq 1 ] ; then
      return 0
  fi

  # pameters are declared and defined here
  # they can be overridden by command line args but once set are read-only
  local -r talend_version="${talend_version_arg:-${talend_version:-${TALEND_VERSION:-8.0.1}}}"
  local -r image_name="${image_name_arg:-${image_name:-${IMAGE_NAME:-talend-distro}}}"

  local -r image_tag="${image_tag:-${image_name}:${talend_version}}"

  # config variables cannot be set by parameters and must be inherited from shell or environment variables
  local base_builder_image
  local base_builder_image_version

  talend_distro_init

  # derived config settings
  local image_tag

  infoVar talend_version
  infoVar image_name
  infoVar base_builder_image
  infoVar base_builder_image_version
  infoVar image_tag
}

function talend_distro_init() {
  base_builder_image="${base_builder_image:-${BASE_BUILDER_IMAGE:-alpine}}"
  base_builder_image_version="${base_builder_image_version:-${BASE_BUILDER_IMAGE_vERSION:-3.18.0}}"
}


function talend_distro_parse_args() {
  local OPTIND=1
  while getopts ":hv:i:" opt; do
    case "$opt" in
      h)
        talend_distro_help
        return 0
        ;;
      v)
        talend_version_arg="${OPTARG}"
        ;;
      i)
        image_name_arg="${OPTARG}"
        ;;
      ?)
        talend_distro_help >&2
        return 2
    esac
  done
}




function talend_distro_help() {
  local help_flag=1
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


function talend_distro_build() {



# parameters

declare -r talend_version="${1:-${talend_version:-8.0.1}}"
declare -r image_name="${image_name:-talend-distro}"

# config can be overridden by shell variables

declare -r base_builder_image="${base_builder_image:-alpine}"
declare -r base_builder_image_version="${base_builder_image_version:-3.18.0}"

declare -r image_tag="${image_tag:-${image_name}:${talend_version}}"

docker buildx build \
  --no-cache \
  --build-arg base_builder_image="${base_builder_image}" \
  --build-arg base_builder_image_version="${base_builder_image_version}" \
  --build-arg talend_version="${talend_version}" \
  --secret id=talend,src=talend.credentials \
  -t "${image_tag}" \
  .
}
