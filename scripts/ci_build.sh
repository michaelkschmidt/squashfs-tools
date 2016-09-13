#!/bin/bash

#
# Build script for Travis
#

set -e
set -v

export CROSS_COMPILE=x86_64-w64-mingw32
export CC=$CROSS_COMPILE-gcc
bash -v scripts/build_pkg.sh
exit 0