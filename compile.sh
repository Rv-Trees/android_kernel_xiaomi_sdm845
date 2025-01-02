#!/bin/sh
#
# Compile script kernel
# Copyright (C) 2024-2025 Rve.

first_help() {
    echo "Usage: $0 [device] [options]"
    echo
    echo "Device:"
    echo "  --beryllium    Compile kernel for beryllium (POCO F1)"
    echo "  --dipper       Compile kernel for dipper (Mi 8)"
    echo "  --equuleus     Compile kernel for equuleus (Mi 8 Pro)"
    echo "  --perseus      Compile kernel for perseus (Mi Mix 3)"
    echo "  --polaris      Compile kernel for polaris (Mi Mix 2S)"
    echo "  --ursa         Compile kernel for ursa (Mi 8 Explorer Edition)"
    echo
    echo "  --help         Display this help message"
    echo
    exit 1
}

second_help() {
    echo "Usage: $0 [device] [options]"
    echo
    echo "Options:"
    echo "  --ksu          with KernelSU"
    echo "  --no-ksu       without KernelSU"
    echo
    echo "  --help         Display this help message"
    echo
    exit 1
}

if [ $# -eq 0 ]; then
    first_help
fi

case "$1" in
    --beryllium)
        DEVICE_CONFIG="beryllium.config"
        ;;
    --dipper)
        DEVICE_CONFIG="dipper.config"
        ;;
    --equuleus)
        DEVICE_CONFIG="equuleus.config"
        ;;
    --perseus)
        DEVICE_CONFIG="perseus.config"
        ;;
    --polaris)
        DEVICE_CONFIG="polaris.config"
        ;;
    --ursa)
        DEVICE_CONFIG="ursa.config"
        ;;
    --help)
        first_help
        ;;
    *)
        echo "Error: Unknown device '$1'"
        first_help
        ;;
esac

if [ $# -lt 2 ]; then
    second_help
fi

case "$2" in
    --ksu)
        CONFIG="mi845-ksu_defconfig"
	OUTPUT_DIR="out/RvKernel/ksu"
        ;;
    --no-ksu)
        CONFIG="mi845_defconfig"
	OUTPUT_DIR="out/RvKernel/non-ksu"
        ;;
    --help)
        second_help
        ;;
    *)
        echo "Error: Unknown option '$2'"
        second_help
        ;;
esac

cat arch/arm64/configs/vendor/xiaomi/$CONFIG \
    arch/arm64/configs/vendor/xiaomi/$DEVICE_CONFIG \
    > arch/arm64/configs/generated_defconfig

DEFCONFIG="generated_defconfig"
CLANGDIR="/home/rve/RvClang"

rm -rf out/compile.log
mkdir -p out

export KBUILD_BUILD_USER=Rve
export KBUILD_BUILD_HOST=RvProject
export USE_CCACHE=1
export PATH="$CLANGDIR/bin:$PATH"

make O=out ARCH=arm64 $DEFCONFIG

start_time=$(date +%s)

rve () {
make -j$(nproc --all) O=out LLVM=1 \
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

end_time=$(date +%s)
compile_time=$((end_time - start_time))

if [ $compile_time -ge 60 ]; then
    compile_time_min=$((compile_time / 60))
    compile_time_sec=$((compile_time % 60))
    echo -e "\033[1;33mCompile time: $compile_time_min minutes and $compile_time_sec seconds\033[0m"
else
    echo -e "\033[1;33mCompile time: $compile_time seconds\033[0m"
fi

mkdir -p $OUTPUT_DIR
mv out/arch/arm64/boot/Image.gz-dtb $OUTPUT_DIR/
