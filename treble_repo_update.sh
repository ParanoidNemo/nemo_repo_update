#!/bin/bash

# exit script immediately if a command fails
set -e


ANDROOT=$PWD
HTTP=https
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

echo ""
echo "  ████████╗██████╗ ███████╗██████╗ ██╗     ███████╗"
echo "  ╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██║     ██╔════╝"
echo "     ██║   ██████╔╝█████╗  ██████╔╝██║     █████╗"
echo "     ██║   ██╔══██╗██╔══╝  ██╔══██╗██║     ██╔══╝"
echo "     ██║   ██║  ██║███████╗██████╔╝███████╗███████╗"
echo "     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝"
echo ""
echo "              applying treble patches..."
echo ""

pushd $ANDROOT/kernel/sony/msm-4.9/kernel
# dtsi: tone: conjure oem into /vendor
git am < $PATCHES_PATH/dtsi-tone-conjure-oem-into-vendor.patch
# dtsi: loire: conjure oem into /vendor
git am < $PATCHES_PATH/dtsi-loire-conjure-oem-into-vendor.patch
popd

pushd $ANDROOT/kernel/sony/msm-4.14/kernel
# dtsi: tone: conjure oem into /vendor
git am < $PATCHES_PATH/dtsi-tone-conjure-oem-into-vendor.patch
# dtsi: loire: conjure oem into /vendor
git am < $PATCHES_PATH/dtsi-loire-conjure-oem-into-vendor.patch
popd

pushd $ANDROOT/build/make
# releasetools: Skip adding compatiblity.zip
git am < $PATCHES_PATH/build-releasetools-skip-compatiblity-zip.patch
popd

pushd $ANDROOT/device/sony/common
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-common"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK

# TODO: Unused as of now
# Revert: Switch selinux to enforcing
# (needed because there might be problems with misbehaving GSI sepolicies)
#git revert --no-edit selinux-enforcing-temp-tag

# git checkout 'treble-odm'
# Use oem as /vendor and add treble quirks
apply_commit 2ba4c51c8952619d4df40ed16ec91f4c16924b6b
popd


pushd $ANDROOT/device/sony/tone
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-tone"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
# git checkout 'treble-odm'
# Use oem as /vendor
apply_commit 025f56891b9d6ec3a86f0c84fab534119a3b2006
popd

pushd $ANDROOT/device/sony/loire
LINK=$HTTP && LINK+="://git.ix5.org/felix/device-sony-loire"
(git remote --verbose | grep -q $LINK) || git remote add ix5 $LINK
# git checkout 'treble-odm'
# Use oem as /vendor
apply_commit 1170e85e4567e44314eff0b55566957632c8b2bc
popd

pushd $ANDROOT/system/core
# init: Always allow permissive
# Horrible workaround to get permissive SELinux in user builds
git am < $PATCHES_PATH/system-core-always-allow-permissive.patch
popd


# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo ""
echo "  ████████╗██████╗ ███████╗██████╗ ██╗     ███████╗"
echo "  ╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██║     ██╔════╝"
echo "     ██║   ██████╔╝█████╗  ██████╔╝██║     █████╗"
echo "     ██║   ██╔══██╗██╔══╝  ██╔══██╗██║     ██╔══╝"
echo "     ██║   ██║  ██║███████╗██████╔╝███████╗███████╗"
echo "     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚══════╝"
echo ""
echo "        all treble patches applied successfully!"
echo ""


echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "        DO NOT FORGET TO INCLUDE device/sony/customization!!!"
echo ""
echo "         ELSE YOUR DEVICE WILL NOT BOOT!!!!"
echo ""
echo ""
echo "          ALSO COPY THE ODM FILES!!!!"
echo ""

set +e
