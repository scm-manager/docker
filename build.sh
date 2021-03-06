#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

IMAGE="scmmanager/scm-multiarch-test"
VERSION="$1"
COMMIT_SHA="${2:-unknown}"

QEMU_PLATFORM="arm,arm64"
PLATFORM="linux/arm/v7,linux/arm64/v8,linux/amd64"

BUILDER=scm-builder
if ! docker buildx inspect ${BUILDER} > /dev/null 2>&1; then
  # https://github.com/docker/buildx/issues/495#issuecomment-761562905
  # https://github.com/docker/buildx#building-multi-platform-images
  # https://hub.docker.com/r/tonistiigi/binfmt
  docker run --privileged --rm tonistiigi/binfmt --install "${QEMU_PLATFORM}"
  docker buildx create --name ${BUILDER} --driver docker-container --platform "${PLATFORM}"
  docker buildx inspect --bootstrap ${BUILDER}
else
  echo "builder ${BUILDER} is already installed"
fi

# build and push
docker buildx build \
  --builder ${BUILDER} \
  --platform "${PLATFORM}" \
  --build-arg "VERSION=${VERSION}" \
  --build-arg "COMMIT_SHA=${COMMIT_SHA}" \
  -t "${IMAGE}:${VERSION}" \
  --push .
