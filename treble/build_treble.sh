#
# Copyright (C) 2020 aclegg2011
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#  Version: Treble GSI Builder 0.8
#  Updated: 3/8/20
#

#!/bin/bash

# Use ccache if installed
export USE_CCACHE=1

rom_fp="$(date +%m%d%y)"
originFolder="$(dirname "$0")"
mkdir -p release/$rom_fp/

# Import/create build-rom.cfg variables
rm -rf build_treble.cfg
cat > build_treble.cfg << EOF
rompath=$(pwd)
build_variant=""
build_variant_name=""
build_options=""
rom_variant=""
clean="n"
cleanOption=""
patch="n"
patchOption=""
sync="n"
syncOption=""
EOF

manifest_url="https://android.googlesource.com/platform/manifest"
aosp="android-10.0.0_r31"
phh="android-10.0"

#Import build-rom.cfg variables
source build-rom.cfg

# Clear Terminal Screeen
clear

# Define USER and define how many threads the cpu has
if [ -z "$USER" ];then
        export USER="$(id -un)"
fi

if [[ $(uname -s) = "Darwin" ]];then
        jobs=$(sysctl -n hw.ncpu)
elif [[ $(uname -s) = "Linux" ]];then
        jobs=$(nproc)
fi

# Code that interputs the command line switches
while test $# -gt 0
do
  case $1 in

  # Normal option processing
    -c | --clean)
      clean="y";
      echo "Clean build."
      ;;
    -s | --sync)
      sync="y"
      echo "Repo sync."
      ;;
    -p | --patch)
      patch="y";
      echo "patching selected."
      ;;
  # ...

  # Special cases
    --)
      break
      ;;
    --*)
      # error unknown (long) option $1
      ;;
    -?)
      # error unknown (short) option $1
      ;;

  # FUN STUFF HERE:
  # Split apart combined short options
    -*)
      split=$1
      shift
      set -- $(echo "$split" | cut -c 2- | sed 's/./-& /g') "$@"
      continue
      ;;

  # Done with options
    *)
      break
      ;;
  esac

  # for testing purposes:
  shift
done

display_help(){
      echo "Usage: $0 options buildVariants"
      echo "options: -c | --clean : Does make clean && make clobber and resets the treble device tree"
      echo "         -s | --sync: Repo syncs the rom (clears out patches), then reapplies patches to needed repos"
      echo "         -p | --patches: reapplies patches"
      echo ""
      echo "buildVariants:  arm64_a_stock | arm64_ab_stock : Vanilla Rom"
      echo "                arm64_a_gapps | arm64_ab_gapps : Stock Rom with Gapps Built-in"
      echo "                arm64_a_foss  | arm64_ab_foss  : Stock Rom with Foss"
      echo "                arm64_a_go    | arm64_ab_go    : Stock Rom with Go-Gapps"
      echo ""
}


if [ "$1" = "arm64_a_stock" ];then
        build_variant=treble_arm64_avN-userdebug;
        build_variant_name=arm64-a-stock;

elif [ "$1" = "arm64_a_gapps" ];then
        build_variant=treble_arm64_agS-userdebug;
        build_variant_name=arm64-a-gapps;

elif [ "$1" = "arm64_a_foss" ];then
        build_variant=treble_arm64_afS-userdebug;
        build_variant_name=arm64-a-foss;

elif [ "$1" = "arm64_a_go" ];then
        build_variant=treble_arm64_aoS-userdebug;
        build_variant_name=arm64-a-go;

elif [ "$1" = "arm64_ab_stock" ];then
        build_variant=treble_arm64_bvN-userdebug;
        build_variant_name=arm64-ab-stock;

elif [ "$1" = "arm64_ab_gapps" ];then
        build_variant=treble_arm64_bgS-userdebug;
        build_variant_name=arm64-ab-gapps;

elif [ "$1" = "arm64_ab_foss" ];then
        build_variant=treble_arm64_bfS-userdebug;
        build_variant_name=arm64-ab-foss;

elif [ "$1" = "arm64_ab_go" ];then
        build_variant=treble_arm64_boS-userdebug;
        build_variant_name=arm64-ab-go;
else
        display_help
fi


# these variables can't be stored in the .cfg file
build_options=$cleanOption$syncOption$patchOption

# If build_options is not empty add the - options flag
if [ ! -z $build_options ];then
   build_options=-$cleanOption$syncOption$patchOption
fi


if [ -d .repo/local_manifests ] ;then
        echo "Local_manifests already exists"
else
        (mkdir -p .repo/local_manifests; cd .repo/local_manifests; cp ../../vendor/aosp/treble/manifests/* $(pwd); cd ../../)
fi

read -p "Continuing in 1 second..." -t 1
echo "Continuing..."


# If statement for $sync
if  [  $sync == "y" ];then
    repo init -u "$manifest_url" -b $aosp
    repo sync -c -j$jobs --no-tags --no-clone-bundle --force-sync
    repo forall -r '.*opengapps.*' -c 'git lfs fetch && git lfs checkout'
    (cd device/phh/treble; git clean -fdx; bash generate.sh)
    (cd vendor/foss; git clean -fdx; bash update.sh)
    rm -f vendor/gapps/interfaces/wifi_ext/Android.bp
    bash "vendor/aosp/treble/autopatch_treble.sh" $rompath/vendor/aosp/treble/patches
    syncOption="s"
fi

# If statment for $patch
if [ $patch == "y" ] ;then
    echo "Let the patching begin"
    bash "vendor/aosp/treble/autopatch_treble.sh" $rompath/vendor/aosp/treble/patches
    patchOption="p"
fi

# If statment for $clean
if [ $clean == "y" ];then
    make -j$jobs clean
    cleanOption="c"
fi

if [[ "$1" = "arm64_a_stock" || "$1" = "arm64_a_gapps" || "$1" = "arm64_a_foss" || "$1" = "arm64_a_go" || "$1" = "arm64_ab_stock" || "$1" = "arm64_ab_gapps" || "$1" = "arm64_ab_foss" || "$1" = "arm64_ab_go" ]];then
echo "Setting up build env for $1"
. build/envsetup.sh
fi

# Build treble rom function
BuildVariant_treble() {
        lunch $1
        make BUILD_NUMBER=$rom_fp installclean
        make BUILD_NUMBER=$rom_fp -j$jobs systemimage
        make BUILD_NUMBER=$rom_fp vndk-test-sepolicy
        echo "Compressing the system.img to release/$rom_fp/system-$build_variant_name.img.xz"
        xz -c $OUT/system.img -T0 > release/$rom_fp/system-$build_variant_name.img.xz
}

if [[ "$1" = "arm64_a_stock" || "$1" = "arm64_a_gapps" || "$1" = "arm64_a_foss" || "$1" = "arm64_a_go" || "$1" = "arm64_ab_stock" || "$1" = "arm64_ab_gapps" || "$1" = "arm64_ab_foss" || "$1" = "arm64_ab_go" ]];then
     BuildVariant_treble $build_variant $build_variant_name
fi
