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


pushd $ANDROOT/kernel/sony/msm-4.14/kernel
LINK=$HTTP && LINK+="://github.com/sonyxperiadev/kernel"
# kconfig: lxdialog: Stub out pkg-config for Android Q build system
apply_pull_commit 2120 30a925da2ef63fa0952217e5007428fce4a68dcd
# kbuild: allow to use GCC toolchain not in Clang search path
apply_pull_commit 2120 3ce88ea4c3ff1fcdd9bd3213a9035d0360aa7873
# kbuild: add -no-integrated-as Clang option unconditionally
apply_pull_commit 2120 1cf4cbf61c93ee41ae8b6db35828c4828240b100
# kbuild: fix false positive warning/error about missing libelf
apply_pull_commit 2120 65917fd7f6e1774a73296bad548a6ba998a31530
# kbuild: clang: choose GCC_TOOLCHAIN_DIR not on LD
apply_pull_commit 2120 d19481bcedca88154bbf32d19fdc1cd17bfa48a6
# kbuild: consolidate Clang compiler flags
apply_pull_commit 2120 7789cbc2bc884ae53fcfed902c10f4fcbb53aff9
# Makefile: Fix qcom's clang merge mess
apply_pull_commit 2120 edf2fb34f09d8336eecfc171a411ee5d1a6a97fe
# kbuild: initialize CLANG_FLAGS correctly in the top Makefile
apply_pull_commit 2120 d3fdff3b7d366bf9c846724ce444c94c79637b41

# TEMP: Build-able makefile for qr and 4.14
git am < $PATCHES_PATH/q-kernel-4.14.patch
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

LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-common"
# TODO: Remove me once merged into Q/master

# https://github.com/sonyxperiadev/device-sony-common/pull/616
# power: No subsystem stats in user builds
apply_pull_commit 616 76fc5c2fb36a3f1bfe24d51daa04caeb5ce14fdb

# https://github.com/sonyxperiadev/device-sony-common/pull/669
# Move BUILD_KERNEL to CommonConfig
apply_pull_commit 669 86022be6c8db1b705febb8542180ae455fee8635
# Move setting KERNEL_PATH to common
apply_pull_commit 669 c750ecfbbe9c967227e7e80994dce0e9d6bbddb2
# CommonConfig: Unify DTBOIMAGE vars
apply_pull_commit 669 9dd2ee55a134c3b5cbca847fba25d15e69f36597
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

# git checkout 'treble-buildvars'
# platform/Platform: Enable VNDK, linker ns
apply_commit 25e58e5989bb4f50845e83b0349811102b5a69b3

# TODO: Remove me once merged into Q/master
LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-tone"
# platform.mk: Move KERNEL_PATH to common
apply_pull_commit 188 5337faa4a7222158e312c498128ee2bc0bd74c11
popd


pushd $ANDROOT/device/sony/tama
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-tama"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
do_if_online git fetch ix5

# git checkout 'avb-allow-disable-verity'
# PlatformConfig: Allow unverified images
apply_commit 28915c56a25f9965aa22487366ba69ed8e78574b

# TODO: Remove me once merged into Q/master
LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-tama"
# PlatformConfig: (Unconditionally) TARGET_NEEDS_DTBOIMAGE
apply_pull_commit 76 844349867e5853cfcf9d669518aba2f3d9b4c7bb
# platform.mk: Move KERNEL_PATH to common
apply_pull_commit 76 eac5da5a1506de78b6dbb22f64777ae17dbb6d32
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

pushd $ANDROOT/device/sony/apollo
LINK=$HTTP && LINK+="://github.com/sonyxperiadev/device-sony-apollo"
# BoardConfig: Unify DTBOIMAGE defs in tama+common
apply_pull_commit 23 19243695b21e1096f3df451161cc0a6bcbd9be8d
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
