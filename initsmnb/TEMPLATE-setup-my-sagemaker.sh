#!/bin/bash

# Utility function to get script's directory (deal with Mac OSX quirkiness).
# This function is ambidextrous as it works on both Linux and OSX.
get_bin_dir() {
    local READLINK=readlink
    if [[ $(uname) == 'Darwin' ]]; then
        READLINK=greadlink
        if [ $(which greadlink) == '' ]; then
            echo '[ERROR] Mac OSX requires greadlink. Install with "brew install greadlink"' >&2
            exit 1
        fi
    fi

    local BIN_DIR=$(dirname "$($READLINK -f ${BASH_SOURCE[0]})")
    echo -n ${BIN_DIR}
}

BIN_DIR=$(get_bin_dir)
ENABLE_EXPERIMENTAL=0

# Ensure that we run only on a SageMaker classic notebook instance.
${BIN_DIR}/ensure-smnb.sh
[[ $? != 0 ]] && exit 1

# Placeholder to store persistent config files
mkdir -p ~/SageMaker/.initsmnb.d

# Hold symlinks of select binaries from the 'base' conda environment, so that
# custom environments don't have to install them, e.g., nbdime, docker-compose.
mkdir -p ~/.local/bin

${BIN_DIR}/install-cli.sh
${BIN_DIR}/adjust-sm-git.sh 'Firstname Lastname' first.last@email.abc
${BIN_DIR}/change-jlab-ui.sh
${BIN_DIR}/fix-osx-keymap.sh
${BIN_DIR}/patch-bash-config.sh
${BIN_DIR}/fix-ipython.sh
${BIN_DIR}/init-vim.sh
${BIN_DIR}/install-cdk.sh
${BIN_DIR}/mount-efs-accesspoint.sh fsid,fsapid,mountpoint

# These require jupyter lab restarted and browser reloaded, to see the changes.
${BIN_DIR}/patch-jupyter-config.sh

if [[ $ENABLE_EXPERIMENTAL == 1 ]]; then
    # NOTE: comment or uncomment tweaks in this stanza as necessary.

    # Disable jupyterlab git extension. For power git users, who don't like to
    # be distracted by jlab's frequent status changes on lower-left status bar.
    ~/anaconda3/envs/JupyterSystemEnv/bin/jupyter labextension disable '@jupyterlab/git'

    # To prevent .ipynb_checkpoints/ in the tarball generated by SageMaker SDK
    # for training scripts, framework processing scripts, and model repack.
    echo "c.FileCheckpoints.checkpoint_dir = '/tmp/.ipynb_checkpoints'" \
        >> ~/.jupyter/jupyter_notebook_config.py

    # Dances needed before we can start using the SageMaker local mode.
    ${BIN_DIR}/enable-sm-local-mode.sh

    # ~/SageMaker EBS can be upsized on demand and survives reboot. Hence, use
    # it for images, layers, caches, build temp dirs, etc.
    ${BIN_DIR}/change-docker-data-root.sh
    ${BIN_DIR}/change-docker-tmp-dir.sh

    ${BIN_DIR}/restart-docker.sh
fi

# Final checks and next steps to see the changes in-effect
${BIN_DIR}/final-check.sh
