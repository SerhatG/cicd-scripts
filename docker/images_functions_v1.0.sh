#!/usr/bin/env bash

# Docker image that we will use to run `yq`
YQ_DOCKER_IMAGE='mikefarah/yq:3'

# Docker compose image containing compose binary
COMPOSE_DOCKER_IMAGE='docker/compose-bin:v2.27.0'

# Directory to put generated theme/files in
GENERATED_DIRECTORY='generated'

# docker-compose.yaml path
DOCKER_COMPOSE_PATH="${GENERATED_DIRECTORY}/docker-compose.yaml"

# Custom profile filename
CUSTOM_PROFILE_FILENAME='custom.profile'

# function to print error and exit
# $1 = error message
function _error() {
  echo '[ERROR] - '"${1}"
  exit 1
}

# function to check if a module is enabled
# $1 = contains modules that are enabled separated by space or empty/not set which means all modules are enabled
# $2 = module to check for
function _is_module_enabled() {
  [[ -z "${1}" ]] || [[ "${1}" == *" ${2} "* ]]
  return $?
}

# function to call yq via Docker - all arguments will be passed along to the yq binary
# yq is a YML processor
function _yq() {
  docker run --rm -i -v "${PWD}":/workdir "${YQ_DOCKER_IMAGE}" yq "${@}"
}

# function to update yq image
function _update_image_yq() {
  docker pull "${YQ_DOCKER_IMAGE}"
}

# function to copy a block of yaml into the resulting yaml
# $1 = yaml to copy to
# $2 = yaml to copy from
# $3 = path of block to copy
function _copy_yaml_block_into() {
  local TEMPFILE="${GENERATED_DIRECTORY}/${3}.yaml"
  touch "${TEMPFILE}"

  _yq read -e "${2}" "${3}" > "${TEMPFILE}"
  _yq prefix --inplace "${TEMPFILE}" "${3}"
  _yq merge -i "${1}" "${TEMPFILE}"
}

# function to call docker compose - all arguments will be passed along to the compose binary
function _docker-compose() {
  .bin/compose "${@}"
}

function _prepare_docker_compose() {
  if [[ -x .bin/compose ]]; then
    echo '- compose binary found.. Skipping..'
  else
    mkdir -p .bin
    COMPOSE_IMAGE_ID=$(docker create "${COMPOSE_DOCKER_IMAGE}" sleep 1m)
    docker cp "${COMPOSE_IMAGE_ID}":/docker-compose .bin/compose
    docker rm "${COMPOSE_IMAGE_ID}"
  fi
}
