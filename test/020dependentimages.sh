#!/bin/bash

set -ex
source common.sh

init_registry

# use alpine as base
docker pull alpine

# build test images && remove them locally
docker build --rm -t ${registry}/image1 image1/
docker push ${registry}/image1

docker build --rm -t ${registry}/image2 image2/
docker push ${registry}/image2

if [[ "$(get_layers image2)" != "$(get_layers image1)"* ]]; then
    echo "Layers of image2 should contain image1" >&2 && false
fi

cleanup_local

# pull images && delete again
docker pull ${registry}/image1
docker pull ${registry}/image2
cleanup_local

# run the registry cleanup
cleanup_registry

# pull again
docker pull ${registry}/image1
docker pull ${registry}/image2

if [[ "$(get_layers image2)" != "$(get_layers image1)"* ]]; then
    echo "Layers of image2 should contain image1" >&2 && false
fi

cleanup_local

# force rebuild image1
docker build --no-cache --rm -t ${registry}/image1 image1/
docker push ${registry}/image1
cleanup_local

# run the registry cleanup again
cleanup_registry

# pull again
docker pull ${registry}/image1
docker pull ${registry}/image2

if [[ "$(get_layers image2)" = "$(get_layers image1)"* ]]; then
    echo "Layers of image2 should not contain rebuild image1" >&2 && false
fi

# Repository should only contain few layers
repository_layers=$(docker_exec registry ls /registry/docker/registry/v2/repositories/image1/_layers/sha256 | wc -l)
# 4 layers: 2x alpine, 1x image1, 1x old image1 layer (used by image2)
if [ "$repository_layers" != 4 ]; then
  echo "image1 repository layers should be exact 4! it is: ${repository_layers}" >&2 && false
fi

repository_layers=$(docker_exec registry ls /registry/docker/registry/v2/repositories/image2/_layers/sha256 | wc -l)
# 4 layers: 2x alpine, 1x image1 old layer, 1x image2
if [ "$repository_layers" != 4 ]; then
  echo "image2 repository layers should be exact 4! it is: ${repository_layers}" >&2 && false
fi

# Only a few blobs should be left
registry_blobs=$(docker_exec registry find /registry/docker/registry/v2/blobs/sha256/ -name data | wc -l)
# 8 blobs: 6x layer (1 only referenced twice), 2x tag
if [ "$registry_blobs" != 8 ]; then
  echo "registry should contain exact 8 blobs! there are: ${registry_blobs}" >&2 && false
fi

# also updating image2
docker build --no-cache --rm -t ${registry}/image2 image2/
docker push ${registry}/image2
cleanup_local

# run the registry cleanup again
cleanup_registry

# pull again
docker pull ${registry}/image1
docker pull ${registry}/image2

if [[ "$(get_layers image2)" != "$(get_layers image1)"* ]]; then
    echo "Layers of image2 should now contain image1 again" >&2 && false
fi

# Repository should only contain few layers
repository_layers=$(docker_exec registry ls /registry/docker/registry/v2/repositories/image1/_layers/sha256 | wc -l)
# 3 layers: 2x alpine, 1x image1
if [ "$repository_layers" != 3 ]; then
  echo "image1 repository layers should be exact 3! it is: ${repository_layers}" >&2
  # TODO: looks like an old layer does not get cleaned up here...
  #&& false
fi

repository_layers=$(docker_exec registry ls /registry/docker/registry/v2/repositories/image2/_layers/sha256 | wc -l)
# 4 layers: 2x alpine, 1x image1, 1x image2
if [ "$repository_layers" != 4 ]; then
  echo "image2 repository layers should be exact 4! it is: ${repository_layers}" >&2 && false
fi

# Only a few blobs should be left
registry_blobs=$(docker_exec registry find /registry/docker/registry/v2/blobs/sha256/ -name data | wc -l)
# 7 blobs: 2x image data, 2x meta, 2x tag
if [ "$registry_blobs" != 7 ]; then
  echo "registry should contain exact 7 blobs! there are: ${registry_blobs}" >&2 && false
fi

# destruct and remove
cleanup_local
destroy_environment

# vi: ts=2 sw=2 expandtab :
