#!/bin/sh

DEFCONFIG="vendor/xiaomi/mi845_defconfig"
CLANGDIR="/home/rve/RvClang"

rm -rf out/compile.log

mkdir -p out
mkdir out/RvKernel

export KBUILD_BUILD_USER=Radika
export KBUILD_BUILD_HOST=Rve27
export USE_CCACHE=1
export PATH="$CLANGDIR/bin:$PATH"

make O=out ARCH=arm64 $DEFCONFIG

MAKE="./makeparallel"

START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

rve () {
make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=1 \
ARCH=arm64 \
CC="ccache clang" \
LD=ld.lld \
AR=llvm-ar \
AS=llvm-as \
NM=llvm-nm \
STRIP=llvm-strip \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
READELF=llvm-readelf \
HOSTCC=clang \
HOSTCXX=clang++ \
HOSTAR=llvm-ar \
HOSTLD=ld.lld \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

rve 2>&1 | tee -a out/compile.log
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Build succesful"
    cp out/arch/arm64/boot/Image.gz-dtb out/RvKernel/Image.gz-dtb
fi

END=$(date +"%s")
DIFF=$(($END - $START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
