#!/bin/bash

set -e

ITERATIONS=1

if [ -n "$1" ]; then
    ITERATIONS="$1"
fi

for i in $(seq 1 "$ITERATIONS"); do
  docker build --no-cache -t localhost:5000/noise noise/
  docker push localhost:5000/noise
done
