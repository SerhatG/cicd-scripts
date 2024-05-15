#!/usr/bin/env bash

# Exit on error
set -e

# Change current directory to directory of script so it can be called from everywhere
SCRIPT_PATH=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

# include functions
source "${SCRIPT_DIR}"/images_functions_v1.0.sh

#####################
### The real deal ###
#####################

# Prepare docker compose environment
echo '# Preparing docker compose environment (if needed)'
_prepare_docker_compose
echo

# Push images
echo '# Pushing images'
_docker-compose -f "${DOCKER_COMPOSE_PATH}" --project-directory "${GENERATED_DIRECTORY}" push

