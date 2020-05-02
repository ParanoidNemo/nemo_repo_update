#!/bin/bash

# exit script immediately if a command fails
set -e


ANDROOT=$PWD
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
echo ""
echo "    ██╗     ██╗███╗   ██╗███████╗ █████╗  ██████╗ ███████╗"
echo "    ██║     ██║████╗  ██║██╔════╝██╔══██╗██╔════╝ ██╔════╝"
echo "    ██║     ██║██╔██╗ ██║█████╗  ███████║██║  ███╗█████╗"
echo "    ██║     ██║██║╚██╗██║██╔══╝  ██╔══██║██║   ██║██╔══╝"
echo "    ███████╗██║██║ ╚████║███████╗██║  ██║╚██████╔╝███████╗"
echo "    ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo ""
echo "         applying patches for lineage..."
echo ""


pushd $ANDROOT/build/make
## releasetools: Allow flashing downgrades
#git am < $PATCHES_PATH/build-releasetools-allow-flashing-downgrades.patch
# check_boot_jars: Whitelist CAF IMS
git am < $PATCHES_PATH/lineage-build-make-checkbootjars-caf-ims.patch
popd

pushd $ANDROOT/build/soong
# Android.bp: Fake Windows libwinpthread src
git am < $PATCHES_PATH/lineage-build-soong-fake-winpthread.patch
popd

pushd $ANDROOT/frameworks/base
# tests: net: Remove libapf deps
git am < $PATCHES_PATH/lineage-fwb-remove-libapf-dep.patch
popd

pushd $ANDROOT/device/sony/common
LINK="https://git.ix5.org/felix/device-sony-common"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5
# git checkout 'selinux-enforcing'
# Switch selinux to enforcing
apply_commit 1fc8e752c33ae07fe8c8f6d48abb2d1324b64536
set +e
if [ $(git tag -l "selinux-enforcing-temp-tag") ]; then
    git tag -d selinux-enforcing-temp-tag
fi
set -e
git tag selinux-enforcing-temp-tag

# git checkout 'add-vendor-ix5'
# Include vendor-ix5 via common.mk
#apply_commit 891d072a7e515d7e69b075b587a7baf569b54b14

# init: Remove verity statements
#apply_commit 6c33a4a8f5fe4615235df9d7abcfe3644f299672

# TODO: Remove me once merged into p-mr1

# git checkout 'vintf-enforce'
# Enforce usage of vintf manifest
apply_commit 5df1a36972a8709f76463f8fe184d472e75d93a1

# git checkout 'remove-packages'
# common-packages: Remove p2p_supplicant.conf
# TODO: is in master, needs to land in p-mr1
#apply_commit 16b818d79d1fab29bb24dc8a9281621e88c52cce
# common-packages: Remove libemoji
# TODO: is in master, needs to land in p-mr1
#apply_commit b5790e2affe1e0707e0cfaef4b550e3b17fc5acf
# common-treble: nfc: Remove @1.1-impl
# TODO: is in master, needs to land in p-mr1
#apply_commit f0bc81b29670a8b6402dc1c26b47da60a0ea4701

LINK="https://github.com/sonyxperiadev/device-sony-common"

# https://github.com/sonyxperiadev/device-sony-common/pull/617
# odm: Use PRODUCT_ODM_PROPERTIES for version
apply_pull_commit 617 aefced5342afec013bff975f04050762a6c89b78
# odm: Only build if SONY_BUILD_ODM is set
apply_pull_commit 617 6662f576ecf2957528ed2fd8b8e35506259a897b
# odm: Include qti blobs in common-odm
apply_commit 2019f8b5499d553c51b000202a2a62121f8568e6

# https://github.com/sonyxperiadev/device-sony-common/pull/616
# power: No subsystem stats in user builds
apply_pull_commit 616 76fc5c2fb36a3f1bfe24d51daa04caeb5ce14fdb

# https://github.com/sonyxperiadev/device-sony-common/pull/615
# power: Add interface info to .rc
# TODO: is in master, needs to land in p-mr1
#apply_pull_commit 615 bcc1358c046cfac4b06a0faa3c0350e1d412760b
# power: Fix unused var in Hints.cpp
# TODO: is in master, needs to land in p-mr1
#apply_pull_commit 615 ff71c5951b3ace5c48eef2ab094c3955af0105d4

# https://github.com/sonyxperiadev/device-sony-common/pull/613
# init: Change toybox SELinux run context
# TODO: is in master, needs to land in p-mr1
#apply_pull_commit 613 aa92c5824275d9b848f563aebe9b4a2a66c0eb76
# init: Wipe updated xattr from /persist/
# TODO: is in master, needs to land in p-mr1
#apply_pull_commit 613 305913cf13ee4d405783fd35d20ce47341313f2c

# [Q-COMPAT] common: Set PRODUCT_BUILD_RECOVERY_IMAGE=true
apply_pull_commit 633 fefbd687d2af9038246abd3da260409d01c4d2ed

# https://github.com/sonyxperiadev/device-sony-common/pull/606
# Revert "common-prop: Enable dmic fluence for voicerec case"
apply_pull_commit 606 fe3f8ffb83a0f0a729aa8294c3fc8b39961d4bd4
popd


pushd $ANDROOT/device/sony/sepolicy
LINK="https://git.ix5.org/felix/device-sony-sepolicy"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# git checkout 'toybox-vendor-init'
# Add vendor_toolbox context
# TODO: is in master, needs to land in p-mr1
#apply_commit 8bfd45c7f845ab357e7117382ebf189e06d16d33
# vendor_toolbox: Allow removing xattr from /persist
# TODO: is in master, needs to land in p-mr1
#apply_commit 46959678c910300d687fcc72cd5a2aae0af6e28f
# vendor_init: Strip unneeded toybox-related permissions
# TODO: is in master, needs to land in p-mr1
#apply_commit 96ae44e5fa6784f50f6e63f5a5762d723080ebff
# vendor_toolbox: Allow SYS_ADMIN
# TODO: is in master, needs to land in p-mr1
#apply_commit 0f780bf6daa08d13c3738f1508fce35364164634

# git checkout 'kernel-socket'
# kernel: debugfs_wlan only in debug builds
# TODO: is in master, needs to land in p-mr1
#apply_commit 444894b98f8d14c3f0b64a1ba23b19a907638b2f

LINK="https://github.com/sonyxperiadev/device-sony-sepolicy"

# [Q-COMPAT] system_app: Remove obsolete perfprofd dontaudit
apply_pull_commit 531 617c2ebd443f36a54687cc136c86f0880b0f5e1f
popd

#pushd $ANDROOT/system/sepolicy
## UGLY!!!
#git am < $PATCHES_PATH/sepolicy-app-neverallow-exception-matlog.patch
#popd

pushd $ANDROOT/vendor/lineage
# Remove build-kernel task to use SODP makefile
git am < $PATCHES_PATH/lineage-vendor-lineage-remove-kernel-task.patch
popd


# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo ""
echo "    ██╗     ██╗███╗   ██╗███████╗ █████╗  ██████╗ ███████╗"
echo "    ██║     ██║████╗  ██║██╔════╝██╔══██╗██╔════╝ ██╔════╝"
echo "    ██║     ██║██╔██╗ ██║█████╗  ███████║██║  ███╗█████╗"
echo "    ██║     ██║██║╚██╗██║██╔══╝  ██╔══██║██║   ██║██╔══╝"
echo "    ███████╗██║██║ ╚████║███████╗██║  ██║╚██████╔╝███████╗"
echo "    ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo ""
echo ""
echo "       all patches for lineage applied successfully!"
echo ""


set +e