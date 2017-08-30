#!/bin/bash

set -e

cd `readlink -f "$(dirname "$0")"`/test

for file in *.sh
do
  [ -x "$file" ] || continue
  echo "=============================================="
  echo "Running test $file"
  echo "=============================================="
  ./"$file"
done

# vi: ts=2 sw=2 expandtab :
