#!/bin/bash

set -ex
source common.sh

init_registry

cleanup_registry

cleanup_local

destroy_environment

# vi: ts=2 sw=2 expandtab :
