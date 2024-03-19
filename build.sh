#!/bin/bash

set -e

# Check if repo is already installed
if ! command -v repo >/dev/null 2>&1; then
    echo "Repo not found. Installing now..."
    # Create bin directory if it doesn't exist
    mkdir -p ~/bin
    # Download repo script
    curl https://storage.googleapis.com/git-repo-downloads/repo >> ~/bin/repo
    # Make repo script executable
    chmod a+x ~/bin/repo
    # Create symbolic link to /usr/bin/repo
    sudo ln -sf "/home/$(whoami)/bin/repo" "/usr/bin/repo"
    echo "Repo installation complete."
else
    echo "Repo already installed."
fi

# Set Crave to build using LineageOS 21 as base
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs --depth=1

# Install crave if running outside devspace
if [ "${DCDEVSPACE}" == "1" ]; then
    echo 'No need to set up crave, we are already running in devspace!'
else
    mkdir ${HOME}/bin/
    curl -s https://raw.githubusercontent.com/accupara/crave/master/get_crave.sh | bash -s --
    mv ${PWD}/crave ${HOME}/bin/
    sudo ln -sf /home/${USER}/bin/crave /usr/bin/crave
    envsubst < ${PWD}/crave.conf.sample >> ${PWD}/crave.conf
    rm -rf ${PWD}/crave.conf.sample          
fi

# Run inside foss.crave.io devspace, in the project folder
# Remove existing local_manifests
echo "Triggering build!"
echo "Build Queued!"
crave run --no-patch -- "rm -rf .repo/local_manifests/
# Clone local_manifests repository
git clone https://github.com/IMYdev/local_manifest.git --depth 1 -b main .repo/local_manifests
# Sync the repositories
/opt/crave/resync.sh
# Set up build environment
source build/envsetup.sh
# Lunch configuration
lunch lineage_X6816-eng
make installclean
m bacon"

# Pull generated zip files
crave pull out/target/product/*/*.zip

# Upload zips to Telegram
# telegram-upload --to sdreleases tissot/*.zip
