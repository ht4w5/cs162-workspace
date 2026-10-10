#!/bin/bash

set -e

CACHE_DIR="${CACHE_DIR:-/tmp/cache}"
mkdir -p "${CACHE_DIR}"

# Download rustup installer only if not already cached
if [ ! -f "${CACHE_DIR}/rustup-init.sh" ]; then
  curl -k https://sh.rustup.rs -sSf -o "${CACHE_DIR}/rustup-init.sh"
  chmod +x "${CACHE_DIR}/rustup-init.sh"
fi

chmod +x "${CACHE_DIR}/rustup-init.sh"
"${CACHE_DIR}/rustup-init.sh" -y --profile=minimal --default-toolchain 1.62.0