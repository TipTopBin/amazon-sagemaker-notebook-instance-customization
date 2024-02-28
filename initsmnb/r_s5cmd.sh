#!/bin/bash

set -euo pipefail

# Constants
APP=s5cmd
GH=peak/s5cmd

[[ -e ~/.local/bin/s5cmd ]] && exit

mkdir -p ~/.local/bin
cd ~/.local/bin

latest_download_url() {
  if [[ $(uname -i) == "x86_64" ]]; then
    local goarch=64bit
  else
    echo WARNING: to test that this works on gravition, and the need for more precise condition
    local goarch=arm64
  fi
  curl --silent "https://api.github.com/repos/${GH}/releases/latest" |   # Get latest release from GitHub api
    grep "\"browser_download_url\": \"https.*$(uname)-$goarch.tar.gz" |  # Get download url
    sed -E 's/.*"([^"]+)".*/\1/'                                         # Pluck JSON value
}


LATEST_DOWNLOAD_URL=$(latest_download_url)
TARBALL=${LATEST_DOWNLOAD_URL##*/}
curl -LO ${LATEST_DOWNLOAD_URL}

# Go tarball has no root, so we need to create one
DIR=${TARBALL%.tar.gz}
mkdir -p $DIR && cd $DIR && tar -xzf ../$TARBALL && cd .. && rm $TARBALL

[[ -L ${APP}-latest ]] && rm ${APP}-latest
ln -s $DIR ${APP}-latest
ln -s ${APP}-latest/${APP} .

#https://github.com/peak/s5cmd
# if [ ! -f $WORKING_DIR/bin/s5cmd ]; then
#     echo "Setup s5cmd"
#     export S5CMD_URL=$(curl -s https://api.github.com/repos/peak/s5cmd/releases/latest \
#     | grep "browser_download_url.*_Linux-64bit.tar.gz" \
#     | cut -d : -f 2,3 \
#     | tr -d \")
#     # echo $S5CMD_URL
#     wget $S5CMD_URL -O /tmp/s5cmd.tar.gz
#     sudo mkdir -p /opt/s5cmd/
#     sudo tar xzvf /tmp/s5cmd.tar.gz -C $WORKING_DIR/bin
# fi

# mv/sync 等注意要加单引号，注意区域配置
# s5cmd mv 's3://xxx-iad/HFDatasets/*' 's3://xxx-iad/datasets/HF/'
# s5 --profile=xxx cp --source-region=us-west-2 s3://xxx.zip ./xxx.zip