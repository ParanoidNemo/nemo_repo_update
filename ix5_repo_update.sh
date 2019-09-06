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
    if [ -z $OFFLINE ]
    then
        $@
    fi
}

echo ""
echo "         d8b          888888888"
echo "         Y8P          888"
echo "                      888"
echo "         888 888  888 8888888b."
echo "         888 ´Y8bd8P´      ´Y88b"
echo "         888   X88K          888"
echo "         888 .d8´´8b. Y88b  d88P"
echo "         888 888  888  ´Y8888P´"
echo ""
echo ""
echo "         applying ix5 patches..."
echo ""


pushd $ANDROOT/kernel/sony/msm-4.9/kernel
# Enable wakeup_gesture in dtsi table
# You need to discard vendor-sony-kernel or the build system will use
# precompiled dtb files, thus rendering this patch useless
#git am < $PATCHES_PATH/kernel-dtsi-wakeup.patch
# tone: panel: set min brightness to 1.2mA
git am < $PATCHES_PATH/panel-minimum-brightness.patch
# dts: tone: Kill verity
git am < $PATCHES_PATH/dtsi-tone-kill-verity.patch
popd

pushd $ANDROOT/build/make
# releasetools: Allow flashing downgrades
git am < $PATCHES_PATH/build-releasetools-allow-flashing-downgrades.patch
popd

pushd $ANDROOT/packages/apps/Bluetooth
# Disable email module for BluetoothInstrumentionTest
git am < $PATCHES_PATH/bluetooth-disable-email-test.patch
popd

pushd $ANDROOT/packages/apps/Launcher3
# Launcher3QuickStep: Remove useless QuickSearchbar
git am < $PATCHES_PATH/launcher3quickstep-remove-quicksearchbar.patch
popd

pushd $ANDROOT/frameworks/base
# Enable development settings by default
git am < $PATCHES_PATH/enable-development-settings-by-default.patch

#LINK=$HTTP && LINK+="://github.com/Thespartann/android_frameworks_base_microG/"
#(git remote --verbose | grep -q $LINK) || git remote add thespartann $LINK
#git fetch thespartann

# Support UnifiedNlp (microG)
#apply_commit 7a99450a7cf44d65a937d9961982b015d0bc4f95
# Add support for fake signatures, enabled per app by dynamic permission
#apply_commit 4bbf5672df9fbd1c67a1667d8ffa1462f54facd4
popd

pushd $ANDROOT/device/sony/common
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-common"
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
apply_commit 891d072a7e515d7e69b075b587a7baf569b54b14

# init: Remove verity statements
apply_commit 6c33a4a8f5fe4615235df9d7abcfe3644f299672

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

LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-common"

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
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-sepolicy"
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

LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-sepolicy"

# [Q-COMPAT] system_app: Remove obsolete perfprofd dontaudit
apply_pull_commit 531 617c2ebd443f36a54687cc136c86f0880b0f5e1f
popd

pushd $ANDROOT/device/sony/tone
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-tone"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# git checkout 'disable-verity-no-forceencrypt'
# Change forceencrypt to encryptable for userdata
apply_commit af592265685fddf24100cbc1fdcdcb5bfd2260c1
# Disable dm-verity
apply_commit b611c8d91a374f246be393d89f20bbf3fc2ab9f7
popd

pushd $ANDROOT/device/sony/loire
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-loire"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5
# git checkout 'disable-verity-no-forceencrypt'
# Change forceencrypt to encryptable for userdata
apply_commit 2165decc2b97364348e0ce1ae9d099fc5abab430
# Disable dm-verity
apply_commit 740d3882c98a1c698649018ac1ea59e46d6af500
popd


pushd $ANDROOT/device/sony/kagura
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-kagura"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# git checkout 'dt2w'
# Re-enable tap to wake
#apply_commit 90a80f6e42bfd2feca40fbdc8e2b046ff654032a
# Turn dt2w off by default in settings
#apply_commit bc9df19ac1561281f2b10238d9007a803cfaaa06
# git checkout 'brightness'
# Set minimum brightness values to 2 and 1
apply_commit 449f9eccfd292d968a98d08546062aedbf6e1a2d
# git checkout 'rgbcir'
# Add preliminary RGBCIR calibration file
#apply_commit a0253f3de75c52bccb9275ee7eda6cd2f9db539c
popd

pushd $ANDROOT/system/sepolicy
# UGLY!!!
git am < $PATCHES_PATH/sepolicy-app-neverallow-exception-matlog.patch
popd

# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo ""
echo "         d8b          888888888"
echo "         Y8P          888"
echo "                      888"
echo "         888 888  888 8888888b."
echo "         888 ´Y8bd8P´      ´Y88b"
echo "         888   X88K          888"
echo "         888 .d8´´8b. Y88b  d88P"
echo "         888 888  888  ´Y8888P´"
echo ""
echo ""
echo "         all ix5 patches applied successfully!"
echo ""


set +e
