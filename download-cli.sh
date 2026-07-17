#!/usr/bin/env bash
# Downloads the Kargo CLI. Usage:
#   ./download-cli.sh /usr/local/bin/kargo
# Pin a version with:
#   KARGO_VERSION=v1.10.1 ./download-cli.sh /usr/local/bin/kargo

set -e

if [ -z "$1" ]; then
  echo "usage: ./download-cli.sh /usr/local/bin/kargo"
  exit 1
fi

version=${KARGO_VERSION:-$(basename "$(curl -Ls -o /dev/null -w '%{url_effective}' https://github.com/akuity/kargo/releases/latest)")}
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
# Normalize architecture to match Kargo release asset names (amd64/arm64).
case "${arch}" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
esac
download_url=https://github.com/akuity/kargo/releases/download/${version}/kargo-${os}-${arch}

echo "Downloading kargo ${version} (${os}/${arch}) to ${1}"
curl -L -o "${1}" "${download_url}"
chmod +x "${1}"
