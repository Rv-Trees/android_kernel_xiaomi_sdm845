#!/bin/sh
#
# Compile script kernel
# Copyright (C) 2024-2025 Rve.

print_help() {
    echo "Usage: $0 [device] [options]"
    echo "remove out directory if compiling for different device"
    echo
    echo "Device:"
    echo "  --beryllium    compile kernel for beryllium (POCO F1)"
    echo "  --dipper       compile kernel for dipper (Mi 8)"
    echo "  --equuleus     compile kernel for equuleus (Mi 8 Pro)"
    echo "  --perseus      compile kernel for perseus (Mi Mix 3)"
    echo "  --polaris      compile kernel for polaris (Mi Mix 2S)"
    echo "  --ursa         compile kernel for ursa (Mi 8 Explorer Edition)"
    echo
    echo "Options:"
    echo "  --lindroid       with Lindroid support"
    echo "  --lindroid-ksu   with Lindroid and KernelSU support"
    echo "  --ksu            with KernelSU support"
    echo "  --all            compile with all options for all devices"
    echo
    echo "  --help           Display this help message"
    echo
    exit 1
}

compile_kernel() {
    DEVICE=$1
    CONFIG=$2
    OUTPUT_DIR=$3

    echo "Compiling for device: $DEVICE with config: $CONFIG"

    cat arch/arm64/configs/vendor/xiaomi/$CONFIG \
        arch/arm64/configs/vendor/xiaomi/$DEVICE.config \
        > arch/arm64/configs/generated_defconfig

    DEFCONFIG="generated_defconfig"
    CLANGDIR="/home/rve/RvClang"

    if [ -f out/compile.log ]; then
        rm out/compile.log
    fi

    mkdir -p out

    export KBUILD_BUILD_USER=Rve
    export KBUILD_BUILD_HOST=RvProject
    export USE_CCACHE=1
    export PATH="$CLANGDIR/bin:$PATH"

    make O=out ARCH=arm64 $DEFCONFIG

    start_time=$(date +%s)

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
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee -a out/compile.log

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
}

run_all() {
    devices="beryllium dipper equuleus perseus polaris ursa"
    configs="mi845_defconfig mi845-ksu_defconfig mi845-lindroid_defconfig mi845-ksu-lindroid_defconfig"

    total_start_time=$(date +%s)

    for DEVICE in $devices; do
        for CONFIG in $configs; do
            case "$CONFIG" in
                "mi845_defconfig")
                    OUTPUT_DIR="RvKernel/non-ksu/$DEVICE"
                    ;;
                "mi845-ksu_defconfig")
                    OUTPUT_DIR="RvKernel/ksu/$DEVICE"
                    ;;
                "mi845-lindroid_defconfig")
                    OUTPUT_DIR="RvKernel/lindroid/$DEVICE"
                    ;;
                "mi845-ksu-lindroid_defconfig")
                    OUTPUT_DIR="RvKernel/lindroid-ksu/$DEVICE"
                    ;;
            esac
            compile_kernel $DEVICE $CONFIG $OUTPUT_DIR
        done
        rm -rf out
    done

    total_end_time=$(date +%s)
    total_compile_time=$((total_end_time - total_start_time))

    if [ $total_compile_time -ge 60 ]; then
        total_compile_time_min=$((total_compile_time / 60))
        total_compile_time_sec=$((total_compile_time % 60))
        echo -e "\033[1;33mTotal compile time: $total_compile_time_min minutes and $total_compile_time_sec seconds\033[0m"
    else
        echo -e "\033[1;33mTotal compile time: $total_compile_time seconds\033[0m"
    fi
}

if [ $# -eq 0 ]; then
    print_help
fi

if [ "$1" = "--all" ]; then
    run_all
else
    case "$1" in
        --beryllium|--dipper|--equuleus|--perseus|--polaris|--ursa)
            DEVICE="${1#--}"
            DEVICE_CONFIG="$DEVICE.config"
            ;;
        --help)
            print_help
            ;;
        *)
            echo "Error: Unknown device '$1'"
            print_help
            ;;
    esac

    if [ $# -lt 2 ]; then
        CONFIG="mi845_defconfig"
        OUTPUT_DIR="RvKernel/non-ksu/$DEVICE"
        compile_kernel $DEVICE $CONFIG $OUTPUT_DIR
    else
        case "$2" in
            --lindroid)
                CONFIG="mi845-lindroid_defconfig"
                OUTPUT_DIR="RvKernel/lindroid/$DEVICE"
                ;;
            --lindroid-ksu)
                CONFIG="mi845-ksu-lindroid_defconfig"
                OUTPUT_DIR="RvKernel/lindroid-ksu/$DEVICE"
                ;;
            --ksu)
                CONFIG="mi845-ksu_defconfig"
                OUTPUT_DIR="RvKernel/ksu/$DEVICE"
                ;;
            --help)
                print_help
                ;;
            *)
                echo "Error: Unknown option '$2'"
                print_help
                ;;
        esac
        compile_kernel $DEVICE $CONFIG $OUTPUT_DIR
    fi
fi
