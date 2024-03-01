#!/bin/bash

set -euo pipefail

CUSTOM_DIR=/home/ec2-user/SageMaker/custom

# Constants
APP=duf
GH=muesli/duf

latest_download_url() {
  if [[ $(uname -i) == "x86_64" ]]; then
    local arch=amd64
  else
    echo WARNING: to test that this works on gravition, and the need for more precise condition
    local arch=arm64
  fi
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*\/duf_.*_linux_$arch.rpm" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}

LATEST_DOWNLOAD_URL=$(latest_download_url)
# check LATEST_DOWNLOAD_URL empty (Github API rate limit exceeded)
if [[ ! -z $LATEST_DOWNLOAD_URL ]]; then
  echo "Setup duf latest"
  RPM=${LATEST_DOWNLOAD_URL##*/}
  (cd /tmp/ && curl -LO ${LATEST_DOWNLOAD_URL})

  sudo yum localinstall -y /tmp/$RPM && rm /tmp/$RPM

else
  # https://github.com/muesli/duf
  echo "Setup duf 0.8.1"
  if [ ! -f $CUSTOM_DIR/duf.rpm ]; then
      DOWNLOAD_URL="https://github.com/muesli/duf/releases/download/v0.8.1/duf_0.8.1_linux_amd64.rpm"
      wget $DOWNLOAD_URL -O $CUSTOM_DIR/duf.rpm
  fi

  sudo yum localinstall -y $CUSTOM_DIR/duf.rpm
fi