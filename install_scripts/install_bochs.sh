#!/bin/bash

set -e
set -x

VERSION=2.6.7
CACHE_DIR="${CACHE_DIR:-/tmp/cache}"
mkdir -p "${CACHE_DIR}"

# Download only if not already cached
if [ ! -f "${CACHE_DIR}/bochs-${VERSION}.tar.gz" ]; then
  wget -O "${CACHE_DIR}/bochs-${VERSION}.tar.gz" "http://downloads.sourceforge.net/project/bochs/bochs/${VERSION}/bochs-${VERSION}.tar.gz"
fi
tar -xvzf "${CACHE_DIR}/bochs-${VERSION}.tar.gz"
pushd bochs-${VERSION}/

if [[ $(uname -m) =~ ^arm|^aarch ]]; then
  ./configure --enable-gdb-stub --with-x --with-x11 --with-term --with-nogui --build=aarch64-unknown-linux-gnu
else
  ./configure --enable-gdb-stub --with-x --with-x11 --with-term --with-nogui --build=x86_64-unknown-linux-gnu
fi

make install

# Clean up build artifacts only (tarball stays in cache)
popd
rm -rf bochs-${VERSION}/
