#!/bin/bash

set -euo pipefail

# Note: the "${BASH_REMATCH[2]}" here is REPO_NAME from
# [https://example.com/somebody/REPO_NAME.git] or [git@example.com:somebody/REPO_NAME.git]
function clone_or_pull () {
    if [[ $1 =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $1 =~ ^(http.*\/)(.*)$ ]]; then
        echo "${BASH_REMATCH[2]}" ;
        set +e ;
            git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules "$1" \
                || git -C "${BASH_REMATCH[2]}" pull --ff-only ;
        set -e ;
    else
        echo "[ERROR] Invalid URL: $1" ;
        return 1 ;
    fi ;
}


echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"

# Create persistent directories
cd /root
mkdir -p /root/models /root/custom_nodes /root/input /root/user /root/output

# Handle existing ComfyUI directory
if [ -d "ComfyUI" ]; then
    rm -rf ComfyUI
fi

set +e
git clone https://github.com/comfyanonymous/ComfyUI.git
cd /root/ComfyUI

# Using stable version (has a release tag)
git reset --hard "$(git tag | grep -e '^v' | sort -V | tail -1)"
set -e

# Create symlinks for persistent storage
ln -sfn /root/models ComfyUI/models
ln -sfn /root/custom_nodes ComfyUI/custom_nodes
ln -sfn /root/input ComfyUI/input
ln -sfn /root/user ComfyUI/user
ln -sfn /root/output ComfyUI/output

cd /root/ComfyUI/custom_nodes
clone_or_pull https://github.com/ltdrdata/ComfyUI-Manager.git


echo "########################################"
echo "[INFO] Downloading Custom Nodes..."
echo "########################################"

cd /root/ComfyUI/custom_nodes

# General
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere.git
clone_or_pull https://github.com/cubiq/ComfyUI_essentials.git
clone_or_pull https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git

echo "########################################"
echo "[INFO] Downloading Models..."
echo "########################################"

# Models
cd /root/ComfyUI/models
aria2c \
  --input-file=/runner-scripts/download-models.txt \
  --allow-overwrite=false \
  --auto-file-renaming=false \
  --continue=true \
  --max-connection-per-server=5

# Finish
touch /root/.download-complete
