#!/bin/sh
#
# Compile script kernel
# Copyright (C) 2024 Rve.

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --beryllium    Compile kernel for beryllium (POCO F1)"
    echo "  --dipper       Compile kernel for dipper (Mi 8)"
    echo "  --equuleus     Compile kernel for equuleus (Mi 8 Pro)"
    echo "  --perseus      Compile kernel for perseus (Mi Mix 3)"
    echo "  --polaris      Compile kernel for polaris (Mi Mix 2S)"
    echo "  --ursa         Compile kernel for ursa (Mi 8 Explorer Edition)"
    echo "  --help         Display this help message"
    echo
    exit 1
}

if [ $# -eq 0 ]; then
    show_help
fi

case "$1" in
    --beryllium)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/beryllium.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --dipper)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/dipper.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --equuleus)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/equuleus.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --perseus)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/perseus.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --polaris)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/polaris.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --ursa)
        cat arch/arm64/configs/vendor/xiaomi/mi845_defconfig \
            arch/arm64/configs/vendor/xiaomi/ursa.config \
            > arch/arm64/configs/generated_defconfig
        ;;
    --help)
        show_help
        ;;
    *)
        echo "Error: Unknown option '$1'"
        show_help
        ;;
esac

DEFCONFIG="generated_defconfig"
CLANGDIR="/home/rve/RvClang"

rm -rf out/compile.log
mkdir -p out

export KBUILD_BUILD_USER=Rve
export KBUILD_BUILD_HOST=RvProject
export USE_CCACHE=1
export PATH="$CLANGDIR/bin:$PATH"

make O=out ARCH=arm64 $DEFCONFIG

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
