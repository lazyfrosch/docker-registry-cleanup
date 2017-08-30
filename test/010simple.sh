#!/bin/bash

set -ex
source common.sh

init_registry

# build image multiple times
for i in $(seq 1 10); do
  docker build --no-cache --rm -t ${registry}/image1 image1/
  docker push ${registry}/image1
done
cleanup_local

# Run a cleanup
cleanup_registry

# We should be able to pull the image
docker pull ${registry}/image1

# Repository should only contain few layers
repository_layers=$(docker_exec registry ls /registry/docker/registry/v2/repositories/image1/_layers/sha256 | wc -l)
# 3 layers: 2x alpine, 1x image1
if [ "$repository_layers" != 3 ]; then
  echo "image1 repository layers should be exact 3! it is: ${repository_layers}" >&2 && false
fi

# Only a few blobs should be left
registry_blobs=$(docker_exec registry find /registry/docker/registry/v2/blobs/sha256/ -name data | wc -l)
# 4 blobs: 3x layer, 1x tag
if [ "$registry_blobs" != 4 ]; then
  echo "registry should contain exact 4 blobs! there are: ${registry_blobs}" >&2 && false
fi

destroy_environment

# vi: ts=2 sw=2 expandtab :
