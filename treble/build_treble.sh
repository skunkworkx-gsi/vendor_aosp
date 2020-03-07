#!/bin/bash

rom_fp="$(date +%y%m%d)"
originFolder="$(dirname "$0")"
mkdir -p release/$rom_fp/
set -e

if [ -z "$USER" ];then
	export USER="$(id -un)"
fi
export LC_ALL=C

if [[ $(uname -s) = "Darwin" ]];then
        jobs=$(sysctl -n hw.ncpu)
elif [[ $(uname -s) = "Linux" ]];then
        jobs=$(nproc)
fi

manifest_url="https://android.googlesource.com/platform/manifest"
aosp="android-10.0.0_r31"
phh="android-10.0"

repo init -u "$manifest_url" -b $aosp

if [ -d .repo/local_manifests ] ;then
        echo "Local_manifests already exists"
else
        (mkdir -p .repo/local_manifests; cd .repo/local_manifests; cp ../../vendor/aosp/treble/manifests/* $(pwd); cd ../../)
fi

#repo sync -c -j$jobs --no-tags --no-clone-bundle --force-sync

repo forall -r '.*opengapps.*' -c 'git lfs fetch && git lfs checkout'
(cd device/phh/treble; git clean -fdx; bash generate.sh)
(cd vendor/foss; git clean -fdx; bash update.sh)
rm -f vendor/gapps/interfaces/wifi_ext/Android.bp

#if [[ $patch == "y" ]];then
#echo "Let the patching begin"
#bash "vendor/aosp/treble/autopatch_treble.sh" $rompath/vendor/aosp/treble/patches
#fi

find -name \*.bp -exec sed -i -e '/java_api_finder/d' '{}' \;

. build/envsetup.sh

buildVariant() {
	lunch $1
	make BUILD_NUMBER=$rom_fp installclean
	make BUILD_NUMBER=$rom_fp -j$jobs systemimage
	make BUILD_NUMBER=$rom_fp vndk-test-sepolicy
	xz -c $OUT/system.img -T0 > release/$rom_fp/system-${2}.img.xz
}

#repo manifest -r > release/$rom_fp/manifest.xml
#bash "$originFolder"/list-patches.sh
#cp patches.zip release/$rom_fp/patches.zip

#	buildVariant treble_arm64_avS-userdebug quack-arm64-aonly-vanilla
#	buildVariant treble_arm64_agS-userdebug quack-arm64-aonly-gapps
#	buildVariant treble_arm64_bvS-userdebug quack-arm64-ab-vanilla
	buildVariant treble_arm64_bgS-userdebug quack-arm64-ab-gapps
#	buildVariant treble_arm_avS-userdebug quack-arm-aonly-vanilla
#	buildVariant treble_arm_agS-userdebug quack-arm-aonly-gapps
#	buildVariant treble_arm_bvS-userdebug quack-arm-ab-vanilla
#	buildVariant treble_arm_bgS-userdebug quack-arm-ab-gapps
