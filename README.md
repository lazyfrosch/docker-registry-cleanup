Docker Registry Cleanup
=======================

[![Build Status](https://travis-ci.org/lazyfrosch/docker-registry-cleanup.svg?branch=master)](https://travis-ci.org/lazyfrosch/docker-registry-cleanup)

This repository shows you how to clean up a Docker registry / distribution software data storage.

Docker registries tend to hog the disk with no longer used layers and images. While there is a way
to remove repositories and tags, there is no good way to remove old layers and untagged images.

We also want to show how to run this regularly, without the cleanup being a major manual work.

**Disclaimer:** Always backup your data, never use this scripts without testing. Read the license below first!

## Used tools

* [delete-docker-registry-image](https://github.com/burnettk/delete-docker-registry-image)
* [Docker registry garbage-collect](https://docs.docker.com/registry/garbage-collection/)

Other requirements:

* Tested with current Docker / Registry (as of 2017-08-24)
  * Docker `17.05.0-ce`
  * Registry `v2.6.2`
* Docker Compose

## How it works

On running the `cleanup` container, the following happens.

* Docker will execute the `cleanup.py` entrypoint
* A read-only registry is started in background (so users can pull data)
* The script indexes images, tags and layers
* Using `delete_docker_registry_image --untagged -i <repo>` any non referenced layer is removed from the repositories
  (This will only keep the tags and their current layers - all "history" is removed)
* `registry garbage-collect` will be run to clean up all dangling blobs (the real data behind all layers)
* Giving you a summary about how much data remains in the repository

For technical details, see the [cleanup container](cleanup/), its [Dockerfile](cleanup/Dockerfile) and the [cleanup script](cleanup/cleanup.py).

To make that clear, this tool is meant to remove unused and non-visible data from your Docker registry.

Every repository contains layers of previous pushes, and the blob data behind it stays through
`garbage-collect` as long it is referenced by a layer.

## What it should not do

I use *should*, because that is what it is intended and has been tested for in my environments.

BACKUP YOUR DATA before trying it out! You have been warned!

* This method should NOT remove repositories and existing tags
* This method should NOT remove data you can access from the frontend API (docker pull and REST API)

## How to use / test this tool

Here is a quick guide how to use this method.

**1. Build the registry container with cleanup extensions**

This will build the image, check [cleanup directory](cleanup/) for scripts and image instructions.

    docker-compose build cleanup

**2. Bring up the test registry***

    docker-compose up -d registry

**3. Generate some noise (random images)**

This will generate a lot of image uploads to a image called `noise`. It's just
executing a random command, building it without cache. And pushing it to the registry, XX times.

    ./generate-noise.sh 25

**4. Run a dry-run, to see what would be cleaned up**

This command won't change data, and won't start a registry this time.

    docker-compose run --rm cleanup --dry-run --no-registry

**5. Run the cleanup**

During the cleanup, the registry should be available in read-only mode, so you can still pull images.
But you won't be able to push...

    docker-compose stop registry
    docker-compose up cleanup
    docker-compose up -d registry

## Some figures

Here some example data gathered with the `noise` image.

*Note:* Amount of data is not important here, check the amount of layers and blobs!

    [ Data summary : Before cleanup ]
    Number of repositories: 1
    Number of tags: 1
    Number of layers: 50
    Number of blobs: 151
    Total size of blobs: 2.0MiB

    [ Data summary : After cleanup ]
    Number of layers: 1
    Number of blobs: 4
    Total size of blobs: 1.9MiB

## Cleaning up after testing

There will a mess on your test system, from generating the test images, but you can remove "untagged"
images very easily on a local Docker system:

    docker rmi localhost:5000/noise
    docker images -qf dangling=true | xargs -r docker rmi

To remove the test containers (and data in volumes):

    docker-compose down -v

## How to use in production

This method works in production fine from my perspective. Below the summary of an initial cleanup
after months of pushing production data to a registry.

```
[ Data summary : Before cleanup ]
Number of repositories: 119
Number of tags: 186
Number of layers: 1268
Number of blobs: 14327
Total size of blobs: 197.7GiB

[ Data summary : After cleanup ]
Number of layers: 131
Number of blobs: 1397
Total size of blobs: 28.5GiB
```

Basically all you need to do is to run a regular script that does:

``` bash
docker-compose stop registry   # stop the live registry
docker-compose up cleanup      # takes up to a few minutes - depending on size
docker-compose stop cleanup    # ensure its stopped
docker-compose up -d registry  # bring back up the live registry (read-write)
```

## Testing

Please see [test.sh](test.sh) and the [test directory](test/) for some scripts regarding testing.

Currently tested:

* Running the registry and cleanup empty
* Multiple image builds and cleanup
* Cross-building over dependent images, with cleanup

## Contributing

Feel free to contribute, comment and share this guide.

## License

    Copyright 2017 Markus Frosch <markus@lazyfrosch.de>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
