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
echo "         applying patches..."
echo ""


pushd $ANDROOT/kernel/sony/msm-4.14/kernel
#LINK=$HTTP && LINK+="://github.com/sonyxperiadev/kernel"

# TEMP: Build-able makefile for Q and 4.14
#git am < $PATCHES_PATH/q-kernel-4.14-makefile.patch
popd

pushd $ANDROOT/kernel/sony/msm-4.9/kernel
# Enable wakeup_gesture in dtsi table
# You need to discard vendor-sony-kernel or the build system will use
# precompiled dtb files, thus rendering this patch useless
#git am < $PATCHES_PATH/kernel-dtsi-wakeup.patch
# tone: panel: set min brightness to 1.2mA
#git am < $PATCHES_PATH/panel-minimum-brightness.patch
# dts: tone: Kill verity
#git am < $PATCHES_PATH/dtsi-tone-kill-verity.patch
# Update makefiles for Android Q and clang
git am < $PATCHES_PATH/q-kernel-4.9-makefile.patch
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
# core: Add support for MicroG
git am < $PATCHES_PATH/q-fwb-core-Add-support-for-MicroG.patch
popd

pushd $ANDROOT/hardware/interfaces
# FIXME: compatibility: Allow radio@1.1
git am < $PATCHES_PATH/q-hardware-interfaces-allow-radio-1-1-.patch
popd

pushd $ANDROOT/packages/modules/NetworkStack
# tests: net: Remove libapf deps
git am < $PATCHES_PATH/q-networkstack-remove-libapf.patch
popd

pushd $ANDROOT/device/sony/sepolicy
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-sepolicy"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5
# git checkout 'gatekeeper-4.9-qti-compat'
# TEMP: gatekeeper: Add 4.9 QTI compat
apply_commit ca356bc5abfa6a45ff5b82e8d5c8dc43eff0865d
popd

pushd $ANDROOT/device/sony/common
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-common"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# TODO: Unused as of now
# git checkout 'selinux-enforcing'
# Switch selinux to enforcing
#apply_commit 1fc8e752c33ae07fe8c8f6d48abb2d1324b64536
#set +e
#if [ $(git tag -l "selinux-enforcing-temp-tag") ]; then
#    git tag -d selinux-enforcing-temp-tag
#fi
#set -e
#git tag selinux-enforcing-temp-tag

# git checkout 'add-vendor-ix5'
# Include vendor-ix5 via common.mk
apply_commit a259a415bc746c55fb4b213010c7ee1bda34d5b1

# git checkout 'init-remove-verity'
# init: Remove verity statements
apply_commit 6c33a4a8f5fe4615235df9d7abcfe3644f299672

LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-common"
# TODO: Remove me once merged into Q/master

# https://github.com/sonyxperiadev/device-sony-common/pull/616
# power: No subsystem stats in user builds
apply_pull_commit 616 76fc5c2fb36a3f1bfe24d51daa04caeb5ce14fdb

# git checkout 'kernel-rework'
# https://github.com/sonyxperiadev/device-sony-common/pull/669
# Move BUILD_KERNEL to CommonConfig
apply_pull_commit 669 86022be6c8db1b705febb8542180ae455fee8635
# Move setting KERNEL_PATH to common
apply_pull_commit 669 c750ecfbbe9c967227e7e80994dce0e9d6bbddb2
# CommonConfig: Unify DTBOIMAGE vars
apply_pull_commit 669 22fb98284747341d175f58143e2417fadf2faf89

# git checkout 'k4.9-guard-6'
# https://github.com/sonyxperiadev/device-sony-common/pull/666
# TEMP: Kernel 4.9 backward compat
apply_pull_commit 666 e8be6b09fa5e223406d232ffe3b149c27d90867a

LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-common"
# git checkout 'treble-odm-3'
# Use oem as /vendor and add treble quirks
apply_commit e3552cd64513cf5395a7b5c4206eeca0cd2c2c60

# git checkout 'k4.9-re-add-qt-km-gatekeeper'
# common: Add 4.9 gatekeeper/keymaster compat
apply_commit f12d93b221a1ce312e8db1589fd925aa04d51244

# git checkout 'overlay-sta-ap'
# overlay: Move STA-AP configs to platforms
apply_commit 6a67a1a7f89d87dba1419c70c2abd08c1a35816f
# CommonConfig: Move dual STA-AP to platforms
apply_commit f068df37449d04b9286800baf5cec873e991b455
popd


# pushd $ANDROOT/device/sony/tone
# TODO: Remove me once merged into Q/master
# LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-tone"
# platform.mk: Move KERNEL_PATH to common
# apply_pull_commit 188 5337faa4a7222158e312c498128ee2bc0bd74c11

# LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-tone"
# (git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
# do_if_online git fetch ix5

# git checkout 'disable-verity-no-forceencrypt'
# Change forceencrypt to encryptable for userdata
# apply_commit af592265685fddf24100cbc1fdcdcb5bfd2260c1
# Disable dm-verity
# apply_commit b611c8d91a374f246be393d89f20bbf3fc2ab9f7

# git checkout 'revert-kernel-4.14-rebased'
# Revert "move msm8996 devices to kernel 4.14"
# apply_commit 51e624b5800c777e16f4b66b8af9e37248528db1

# git checkout 'k4.9-guard'
# PlatformConfig: Only use DRM/SDE on 4.14
# apply_commit 3d7b19e1af6ca951ffb9a021b6ecd70d903d4dff

# git checkout 'treble-odm-3'
# Use oem as /vendor
# apply_commit 796ff85b93d28a301cce7bd6b3e0852a35180e04
# popd


# pushd $ANDROOT/device/sony/tama
# LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-tama"
# (git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
# do_if_online git fetch ix5

# git checkout 'avb-allow-disable-verity'
# PlatformConfig: Allow unverified images
# apply_commit 28915c56a25f9965aa22487366ba69ed8e78574b

# git checkout 'overlay-sta-ap'
# overlay: Move STA-AP configs from common
# apply_commit 253c5ddfa055e31e6d7d067a965f72f3e233c0d7
# CommonConfig: Move dual STA-AP from common
# apply_commit de5c440244a3fe78b92a4a24e36bdbc6ed20390a

# TODO: Remove me once merged into Q/master
# LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-tama"
# PlatformConfig: (Unconditionally) TARGET_NEEDS_DTBOIMAGE
# apply_pull_commit 76 844349867e5853cfcf9d669518aba2f3d9b4c7bb
# platform.mk: Move KERNEL_PATH to common
# apply_pull_commit 76 eac5da5a1506de78b6dbb22f64777ae17dbb6d32
# popd


# pushd $ANDROOT/device/sony/kagura
# LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-kagura"
# (git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
# do_if_online git fetch ix5

# git checkout 'dt2w'
# Re-enable tap to wake
#apply_commit 90a80f6e42bfd2feca40fbdc8e2b046ff654032a
# Turn dt2w off by default in settings
#apply_commit bc9df19ac1561281f2b10238d9007a803cfaaa06
# git checkout 'brightness'
# Set minimum brightness values to 2 and 1
# apply_commit 449f9eccfd292d968a98d08546062aedbf6e1a2d
# git checkout 'rgbcir'
# Add preliminary RGBCIR calibration file
#apply_commit a0253f3de75c52bccb9275ee7eda6cd2f9db539c
# popd

# pushd $ANDROOT/device/sony/apollo
# LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-apollo"
# BoardConfig: Unify DTBOIMAGE defs in tama+common
# apply_pull_commit 23 19243695b21e1096f3df451161cc0a6bcbd9be8d
# popd

pushd $ANDROOT/system/sepolicy
LINK=$HTTP && LINK+="://android.googlesource.com/platform/system/sepolicy"
# TODO: Remove me once merged into Q/master
# property_contexts: Remove compatible guard
apply_gerrit_cl_commit refs/changes/00/1185400/1 668b7bf07a69e51a6c190d6b366d574b9e4af1d4

# Disabled for now
#git am < $PATCHES_PATH/q-sepolicy-app-neverallow-exception-matlog.patch
#popd

pushd $ANDROOT/system/core
# property_service: Also read /odm/build.prop
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
echo "         all patches applied successfully!"
echo ""


set +e
