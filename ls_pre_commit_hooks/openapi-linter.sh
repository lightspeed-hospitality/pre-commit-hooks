#!/bin/sh
set -e

LINTER_TAG="${OPENAPI_LINTER_VERSION:-21-73a3f80}"
LINTER_IMAGE="809245501444.dkr.ecr.us-east-1.amazonaws.com/release/internal/image/openapi-linter"

container_exists() {
	if [ "$(docker ps -a -f name="$1" | wc -l)" -eq 2 ]; then
		return 0
	else
		return 1
	fi
}

run_circle_ci() {
	linter="$1"
	docker_image="$2"
	container="${linter}-linter-volume"

	shift 2

	if container_exists "${container}"; then
		docker container rm -f "${container}"
	fi

	# create a dummy container which will hold a volume
	docker create -v /src --name "${container}" busybox /bin/true

	# copy sources into this volume
	docker cp "${PWD}/." "${container}:/src"

	# run linter
	docker run --volumes-from "${container}" --workdir /src "${docker_image}" "${linter}" "$@"
}

run_local() {
	linter="$1"
	docker_image="$2"

	shift 2

	docker run -v "${PWD}:/src:rw,Z" --workdir /src "${docker_image}" "${linter}" "$@"
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
