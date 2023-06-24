#!/usr/bin/env bash

[ "${TALEND_DISTRO_BUILD_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_BUILD_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_build() {

  # declare inherited parameters and settings if they do not alreayd exist so that the can be used for initialization
   [ ! "${factory_image+x}" == "x" ] && local factory_image
   [ ! "${talend_version+x}" == "x" ] && local talend_version

  # initialize inherited parameters and settings
  function talend_distro_build_context() {
    factory_image="${factory_image:-${TALEND_DISTRO_FACTORY_IMAGE:-${talend_distro_factory_image_default:-talend-distro}}}"
    talend_version="${talend_version:-${TALEND_DISTRO_TALEND_VERSION:-${talend_distro_talend_version_default:-8.0.1}}}"
  }
  talend_distro_build_context

  # declare parameters
  local factory_base_image
  local factory_base_image_version
  local credentials
  local manifest

  # initialize parameters
  function talend_distro_build_init() {
    factory_base_image="${factory_base_image:-${TALEND_DISTRO_FACTORY_BASE_IMAGE:-${talend_distro_factory_base_image_default:-alpine}}}"
    factory_base_image_version="${factory_base_image_version:-${TALEND_DISTRO_FACTORY_BASE_IMAGE_VERSION:-${talend_distro_factory_base_image_version_default:-3.18.0}}}"
    credentials="${credentials:-${TALEND_DISTRO_CREDENTIALS:-${talend_distro_credentials_default:-talend.credentials}}}"
    manifest="${manifest:-${TALEND_DISTRO_MANIFEST:-${talend_distro_manifest_default:-talend.manifest}}}"
  }
  talend_distro_build_init

  # working variable
  local args

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_build_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro [options...] [arguments...]" ''
      msg -- 'Options:'
      param   talend_version              -v  --talend_version              init:="" pattern:"8.0.1 | 7.3.1"
      param   factory_image               -f  --factory_image               init:=""
      param   factory_base_image          -f  --factory_base_image          init:=""
      param   factory_base_image_version  -g  --factory_base_image_version  init:=""
      param   credentials                 -c  --credentials                 init:=""
      param   manifest                    -m  --manifest                    init:=""
      # shellcheck disable=SC1083
      disp    :usage                      -h                                -- "help summary"
      disp    :usage                          --help                        -- "help details"
    }

    eval "$(getoptions "${parser_name}_def" "${parser_name}")"
  fi

  # call the function arg parser
  "${parser_name}" "${@}"

  # reset the stack $@ variable to the positional arguments
  eval "set -- ${args}"

  # make inherited parameters immutable
  required talend_version factory_image
  readonly talend_version factory_image

  # make parameters immutable
  required factory_base_image factory_base_image_version credentials manifest
  readonly factory_base_image factory_base_image_version credentials manifest

  # configuration settings can be overridden by shell or environment variables

  # calculate derived settings
  local -r image_tag="${factory_image}:${talend_version}"

  # body of the function

  infoVar talend_version
  infoVar factory_image
  infoVar image_tag
  infoVar factory_base_image
  infoVar factory_base_image_version
  infoVar credentials
  infoVar manifest

#    --no-cache \

  docker buildx build \
    --build-arg factory_base_image="${factory_base_image}" \
    --build-arg factory_base_image_version="${factory_base_image_version}" \
    --build-arg talend_version="${talend_version}" \
    --build-arg talend_manifest="${manifest}" \
    --secret id=talend,src="${credentials}" \
    -t "${image_tag}" \
    .

  return 0
}
