#!/usr/bin/env bash

# Exit on error
set -e

# Change current directory to directory of script so it can be called from everywhere
SCRIPT_PATH=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

# include functions
source "${SCRIPT_DIR}"/images_functions_v1.0.sh

# Set variables we will re-use multiple times
PROFILE_PATH="${GENERATED_DIRECTORY}/${CUSTOM_PROFILE_FILENAME}"
DOCKER_COMPOSE_ORIGINAL_PATH="${GENERATED_DIRECTORY}/docker-compose-original.yaml"

# Set variable with whether the custom profile file is found
[[ -f "${PROFILE_PATH}" ]] && PROFILE_PATH_FOUND=0 || PROFILE_PATH_FOUND=1

####################
### Validations ###
###################

# Check if a custom theme exists
if ! ( [[ -d "${GENERATED_DIRECTORY}" ]] || [[ -f "${DOCKER_COMPOSE_ORIGINAL_PATH}" ]] ); then
  _error 'Generated directory not found. Use images_prepare-v1.0.sh to generate one first.'
fi

# Read in profile if it exists
[[ "${PROFILE_PATH_FOUND}" == 0 ]] && source "${PROFILE_PATH}"

#####################
### The real deal ###
#####################

# Prepare docker compose environment
echo '# Preparing docker compose environment (if needed)'
_prepare_docker_compose
echo

# Get latest images (if needed)
echo '# Pulling latest images (if any)'
_docker-compose -f "${DOCKER_COMPOSE_ORIGINAL_PATH}" --project-directory "${GENERATED_DIRECTORY}" pull
echo

# Dump processed docker-compose.yaml
echo '# Dump processed docker-compose.yaml'
_docker-compose -f "${DOCKER_COMPOSE_ORIGINAL_PATH}" --project-directory "${GENERATED_DIRECTORY}" config > "${DOCKER_COMPOSE_PATH}"
echo

# Build images
echo '# Building images'
_docker-compose -f "${DOCKER_COMPOSE_PATH}" --project-directory "${GENERATED_DIRECTORY}" build --pull --parallel --build-arg HTTPS_DATA_USERNAME="${HTTPS_DATA_USERNAME}" --build-arg HTTPS_DATA_PASSWORD="${HTTPS_DATA_PASSWORD}"
