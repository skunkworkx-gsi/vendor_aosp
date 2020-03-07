#!/bin/bash

rom_fp="$(date +%y%m%d)"
originFolder="$(dirname "$0")"
mkdir -p release/$rom_fp/
set -e

if [ -z "$USER" ];then
	export USER="$(id -un)"
fi
export LC_ALL=C

manifest_url="https://android.googlesource.com/platform/manifest"
aosp="android-10.0.0_r31"
phh="android-10.0"

cd ../../../

repo init -u "$manifest_url" -b $aosp
if [ -d .repo/local_manifests ] ;then
	echo "Local_manifests already exists"
else
	(mkdir -p .repo/local_manifests; cd .repo/local_manifests; cp ../../vendor/aosp/treble/manifests/* $(pwd); cd ../../)
fi

cp vendor/aosp/treble/build_treble.sh build_treble.sh
echo "Run build_treble.sh from root dir to sync aosp rom"
