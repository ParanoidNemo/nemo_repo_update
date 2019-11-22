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
# Update makefiles for Android Q and clang
git am < $PATCHES_PATH/q-kernel-q-and-clang.patch
popd

pushd $ANDROOT/kernel/sony/msm-4.14/kernel
# TEMP: Build-able makefile for qr and 4.14
git am < $PATCHES_PATH/q-kernel-q-and-clang.patch
popd

pushd $ANDROOT/build/make
# releasetools: Allow flashing downgrades
git am < $PATCHES_PATH/build-releasetools-allow-flashing-downgrades.patch
# handheld_product: Remove Browser2, QuickSearchBox
git am < $PATCHES_PATH/q-build-make-remove-browser2-quicksearchbox.patch
popd

pushd $ANDROOT/build/soong
# Android.bp: Fake Windows libwinpthread deps
git am < $PATCHES_PATH/q-build-soong-fake-libwinpthread.patch
popd

pushd $ANDROOT/packages/apps/Bluetooth
# Disable email module for BluetoothInstrumentionTest
git am < $PATCHES_PATH/q-bluetooth-disable-email-test.patch
popd

pushd $ANDROOT/packages/apps/Launcher3
# Launcher3QuickStep: Remove useless QuickSearchbar
git am < $PATCHES_PATH/q-launcher3quickstep-remove-quicksearchbar.patch
popd

pushd $ANDROOT/frameworks/base
# Enable development settings by default
git am < $PATCHES_PATH/q-enable-development-settings-by-default.patch
popd

pushd $ANDROOT/hardware/interfaces
# FIXME: compatibility: Allow radio@1.1
git am < $PATCHES_PATH/q-hardware-interfaces-allow-radio-1-1-.patch
popd

pushd $ANDROOT/packages/modules/NetworkStack
# tests: net: Remove libapf deps
git am < $PATCHES_PATH/q-networkstack-remove-libapf.patch
popd

pushd $ANDROOT/device/sony/common
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-common"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# git checkout 'add-vendor-ix5'
# Include vendor-ix5 via common.mk
apply_commit 46965a6dcae27d4358a53dacca1eb8429bff9e70

# git checkout 'init-remove-verity'
# init: Remove verity statements
apply_commit 6c33a4a8f5fe4615235df9d7abcfe3644f299672

# git checkout 'revert-new-media'
# Revert "TEMP: use the new media platform for all devices"
apply_commit 2babda1d5e2599be85e2f406666100ac3e7b7ae8

LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-common"
# TODO: Remove me once merged into Q/master

# https://github.com/sonyxperiadev/device-sony-common/pull/616
# power: No subsystem stats in user builds
apply_pull_commit 616 76fc5c2fb36a3f1bfe24d51daa04caeb5ce14fdb
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

# git checkout 'q-product-build-bootimg'
# platform: Build boot image
apply_commit 19f8a85dcd7d2f1412579b1f0d8da7400552882f

# git checkout 'treble-buildvars'
# platform/Platform: Enable VNDK, linker ns
apply_commit 25e58e5989bb4f50845e83b0349811102b5a69b3

# git checkout 'revert-drm-rendering'
# Revert "PlatformConfig: enable DRM rendering"
apply_commit cf890f70a2de9131b8c23e6ad2bbd1a7f9fc5eae

# git checkout 'revert-kernel-4.14'
# Revert "move msm8996 devices to kernel 4.14"
apply_commit 8bea33cf78921e9eb58d4523809fb9c91ca56388
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

# Disabled for now
#pushd $ANDROOT/system/sepolicy
#git am < $PATCHES_PATH/q-sepolicy-app-neverallow-exception-matlog.patch
#popd

pushd $ANDROOT/system/core
# property_service: Read /odm/build.prop
git am < $PATCHES_PATH/q-system-core-propertyservice-read-odm-buildprop.patch
popd

pushd $ANDROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
# aarch64: Drop sleep constructor
git am < $PATCHES_PATH/q-gcc-sleep-constructor-aarch64.patch
popd
pushd $ANDROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9
# arm: Drop sleep constructor
git am < $PATCHES_PATH/q-gcc-sleep-constructor-arm.patch
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
