#!/usr/bin/env bash
set -e

IMAGE="ghcr.io/amelzulji/grk2727-ws260824"
TAG="$1"

BUILD_ARGS=()

if [[ "${2:-}" == "--no-cache" ]]; then
  BUILD_ARGS+=(--no-cache)
fi

docker build \
  "${BUILD_ARGS[@]}" \
  -t "${IMAGE}:${TAG}" \
  ./docker

docker push "${IMAGE}:${TAG}"