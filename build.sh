#!/bin/bash

# HOME path
export HOME=/home/atndko

# Compiler environment
export CLANG_PATH=$HOME/clang/bin
export PATH="$CLANG_PATH:$PATH"
export DTC_EXT=$(pwd)/tools/dtc
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER=Vwool0xE9
export KBUILD_BUILD_HOST=Atndko

# Kernel version configuration
KNAME="NeptuneKernel"
MIN_HEAD=$(git rev-parse HEAD)
VERSION="$(cat version)-$(date +%m.%d.%y)-$(echo ${MIN_HEAD:0:8})"
IMGNAME="${KNAME}-$(cat version)-$(echo ${MIN_HEAD:0:8})"

export LOCALVERSION="-${KNAME}-$(echo "${VERSION}")"

mkbootimg=~/tools/mkbootimg
ramdisk=~/tools/samsung/ramdisk.cpio.empty

# Show compilation time
START=$(date +"%s")

echo
echo "Setting defconfig"
echo
make CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip neptune_defconfig || exit 1

echo
echo "Compiling"
echo 
make CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(nproc --all) || exit 1

echo
echo "Building Kernel Image"
echo
$mkbootimg \
    --kernel arch/arm64/boot/Image.gz-dtb \
    --ramdisk $ramdisk \
    --cmdline 'console=null androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image' \
    --base           0x00000000 \
    --board          RILRI20A004 \
    --pagesize       4096 \
    --kernel_offset  0x00008000 \
    --ramdisk_offset 0x00000000 \
    --second_offset  0x00000000 \
    --tags_offset    0x01e00000 \
    --os_version     '11.0.0' \
    --os_patch_level '2021-01' \
    --header_version 1 \
    -o $IMGNAME.img

ls -al $IMGNAME.img

# Show compilation time
END=$(date +"%s")
DIFF=$((END - START))
echo -e "Kernel compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
