#!/bin/bash

# exit script immediately if a command fails
set -e


ANDROOT=$PWD
HTTP=https
OFFLINE=$SODP_WORK_OFFLINE
RESOLVED_REPO_PATH="$ANDROOT/$(dirname $(readlink $0))"
PATCHES_PATH=$RESOLVED_REPO_PATH/patches

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

commit_exists() {
    _sha1=$1
    git rev-parse --quiet --verify $_sha1^{commit}
}

apply_commit() {
    _commit=$1
    if commit_exists $_commit
    then
        git cherry-pick $_commit
    else
        git fetch $LINK $_commit && git cherry-pick $_commit
    fi
}

apply_gerrit_cl_commit() {
    _cl=$1
    _commit=$2
    if commit_exists $_commit
    then
        git cherry-pick $_commit
    else
        git fetch $LINK $_cl && git cherry-pick FETCH_HEAD
    fi
}

apply_pull_commit() {
    _pull=$1
    _commit=$2
    if commit_exists $_commit
    then
        git cherry-pick $_commit
    else
        git fetch $LINK pull/$_pull/head && git cherry-pick $_commit
    fi
}

do_if_online() {
    if [[ ! $OFFLINE = true ]]
    then
        $@
    fi
}

echo ""
echo "       ██╗  ██╗    ██╗  ██╗   █████╗"
echo "       ██║ ██╔╝    ██║  ██║  ██╔══██╗"
echo "       █████╔╝     ███████║  ╚██████║"
echo "       ██╔═██╗     ╚════██║   ╚═══██║"
echo "       ██║  ██╗         ██║██╗█████╔╝"
echo "       ╚═╝  ╚═╝         ╚═╝╚═╝╚════╝"
echo ""
echo ""
echo "         applying Kernel 4.9 patches..."
echo ""

pushd $ANDROOT/packages/apps/Launcher3
# Launcher3QuickStep: Remove useless QuickSearchbar
git am < $PATCHES_PATH/q-launcher3quickstep-remove-quicksearchbar.patch
popd

pushd $ANDROOT/frameworks/base
# Enable development settings by default
##git am < $PATCHES_PATH/q-enable-development-settings-by-default.patch
# core: Add support for MicroG
git am < $PATCHES_PATH/q-fwb-core-Add-support-for-MicroG.patch
popd

##pushd $ANDROOT/device/sony/common
# revert: liblights: Migrate to kernel 4.14 LED class for RGB tri-led
##git revert --no-edit 8b79a2321abe42c9d13540651cbf8a276ec7a2f1
##popd


# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo ""
echo "       ██╗  ██╗    ██╗  ██╗   █████╗"
echo "       ██║ ██╔╝    ██║  ██║  ██╔══██╗"
echo "       █████╔╝     ███████║  ╚██████║"
echo "       ██╔═██╗     ╚════██║   ╚═══██║"
echo "       ██║  ██╗         ██║██╗█████╔╝"
echo "       ╚═╝  ╚═╝         ╚═╝╚═╝╚════╝"
echo ""
echo ""
echo "    all Kernel 4.9 patches applied successfully!"
echo ""


set +e

