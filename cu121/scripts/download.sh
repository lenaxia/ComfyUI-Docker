#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"

set -euxo pipefail

# ComfyUI
cd /home/runner

# Handle existing ComfyUI directory
if [ -d "ComfyUI" ]; then
    rm -rf ComfyUI
fi

# Create persistent directories
mkdir -p /home/runner/models /home/runner/custom_nodes /home/runner/input /home/runner/user /home/runner/output

# Clone ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
# Using stable version (has a release tag)
git reset --hard "$(git tag | grep -e '^v' | sort -V | tail -1)"

# Create symlinks for persistent storage
ln -sfn /home/runner/models ComfyUI/models
ln -sfn /home/runner/custom_nodes ComfyUI/custom_nodes
ln -sfn /home/runner/input ComfyUI/input
ln -sfn /home/runner/user ComfyUI/user
ln -sfn /home/runner/output ComfyUI/output

# ComfyUI Manager
cd /home/runner/ComfyUI/custom_nodes
git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules \
    https://github.com/ltdrdata/ComfyUI-Manager.git \
    || (cd /home/runner/ComfyUI/custom_nodes/ComfyUI-Manager && git pull)

echo "########################################"
echo "[INFO] Downloading Models..."
echo "########################################"

# Models
cd /home/runner/ComfyUI/models
aria2c --input-file=/home/scripts/download-models.txt \
    --allow-overwrite=false --auto-file-renaming=false --continue=true \
    --max-connection-per-server=5

# Finish
touch /home/runner/.download-complete
