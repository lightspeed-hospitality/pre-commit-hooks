#!/bin/sh
set -e

LINTER_TAG="${OPENAPI_LINTER_VERSION:-169-f3bf5c4}"
LINTER_IMAGE="809245501444.dkr.ecr.us-east-1.amazonaws.com/release/internal/image/openapi-linter"

container_exists() {
  if [ "$(docker ps -a -f name="$1" | wc -l)" -eq 2 ]; then
    return 0
  else
    return 1
  fi
}

run_circle_ci() {
  # This workaround is required to overcome CircleCI's limitation due to use of remote docker.
  # See here https://circleci.com/docs/building-docker-images/#mounting-folders for details.
  linter="$1"
  docker_image="$2"
  random_suffix=$(uuidgen | tr -d '-')
  container_name="${linter}-linter-volume-${random_suffix}"

  shift 2

  if container_exists "${container_name}"; then
    docker container rm -f "${container_name}"
  fi

  # create a dummy container which will hold a volume
  docker create -v /src --name "${container_name}" busybox /bin/true

  # copy sources into this volume
  docker cp "${PWD}/." "${container_name}:/src"

  # run linter
  docker run --volumes-from "${container_name}" --workdir /src "${docker_image}" "${linter}" "$@"
}

run_local() {
  linter="$1"
  docker_image="$2"
  random_suffix=$(uuidgen | tr -d '-')
  container_name="${linter}-linter-${random_suffix}"

  shift 2

  docker run --rm --name "${container_name}" -v "${PWD}:/src:rw,Z" --workdir /src "${docker_image}" "${linter}" "$@"
}

run() {
  linter="$1"
  docker_image="${LINTER_IMAGE}:${LINTER_TAG}"

  shift

  if [ -n "${CIRCLECI}" ]; then
    echo "Running ${linter} with CircleCI docker volume workaround."
    run_circle_ci "${linter}" "${docker_image}" "$@"
  else
    run_local "${linter}" "${docker_image}" "$@"
  fi
}

run "$@"
