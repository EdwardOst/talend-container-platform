#!/usr/bin/env bash

[ "${TALEND_DISTRO_BUILD_FLAG:-0}" -gt 0 ] && return 0

export TALEND_DISTRO_BUILD_FLAG=1

set -u

# shellcheck source=util/util.sh
source "util/util.sh"

# shellcheck source=util/getoptions/getoptions.sh
source "util/getoptions/getoptions.sh"

function talend_distro_build() {

  # initialize inherited parameters and settings
  local talend_version="${talend_version:-${TALEND_DISTRO_TALEND_VERSION:-${talend_distro_talend_version_default:-8.0.1}}}"
  local factory_image="${factory_image:-${TALEND_DISTRO_FACTORY_IMAGE:-${talend_distro_factory_image_default:-talend-distro}}}"
  local factory_tag="${factory_tag:-${TALEND_DISTRO_FACTORY_TAG:-${talend_distro_factory_tag:-${talend_version}}}}"

  # declare parameters
  local factory_base_image
  local factory_base_image_tag
  local credentials
  local manifest

  # initialize parameters
  factory_base_image="${factory_base_image:-${TALEND_DISTRO_FACTORY_BASE_IMAGE:-${talend_distro_factory_base_image_default:-alpine}}}"
  factory_base_image_tag="${factory_base_image_tag:-${TALEND_DISTRO_FACTORY_BASE_IMAGE_TAG:-${talend_distro_factory_base_image_tag_default:-3.18.0}}}"
  credentials="${credentials:-${TALEND_DISTRO_CREDENTIALS:-${talend_distro_credentials_default:-talend.credentials}}}"
  manifest="${manifest:-${TALEND_DISTRO_MANIFEST:-${talend_distro_manifest_default:-talend.manifest}}}"

  # helper variables
  local args

  local -r parser_name="${FUNCNAME[0]}_parser"
  # shellcheck disable=SC2016
  if [ ! "$(type -t '${parser_name}')" == 'function' ]; then

    function talend_distro_build_parser_def() {
      setup   args plus:true help:usage abbr:true -- "Usage: talend_distro_build [options...] [arguments...]" ''
      msg -- 'Options:'
      param   talend_version              -v  --talend_version              init:="${talend_version}"  pattern:"8.0.1 | 7.3.1"
      param   factory_image               -f  --factory_image               init:="${factory_image}"
      param   factory_tag                 -t  --factory_tag                 init:="${factory_tag}"
      param   factory_base_image              --factory_base_image          init:="${factory_base_image}"
      param   factory_base_image_tag          --factory_base_image_tag      init:="${factory_base_image_tag}"
      param   credentials                 -c  --credentials                 init:="${credentials}"
      param   manifest                    -m  --manifest                    init:="${manifest}"
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
  required talend_version factory_image factory_tag
  readonly talend_version factory_image factory_tag

  # make parameters immutable
  required factory_base_image factory_base_image_tag credentials manifest
  readonly factory_base_image factory_base_image_tag credentials manifest

  # configuration settings can be overridden by shell or environment variables

  # calculate derived settings
  local -r image_tag="${factory_image}:${factory_tag}"

  # body of the function

  infoVar talend_version
  infoVar factory_image
  infoVar factory_tag
  infoVar factory_base_image
  infoVar factory_base_image_tag
  infoVar credentials
  infoVar manifest

#    --no-cache \

  docker buildx build \
    --build-arg factory_base_image="${factory_base_image}" \
    --build-arg factory_base_image_tag="${factory_base_image_tag}" \
    --build-arg talend_version="${talend_version}" \
    --build-arg talend_manifest="${manifest}" \
    --secret id=talend,src="${credentials}" \
    -t "${image_tag}" \
    .

  return 0
}
