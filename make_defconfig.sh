#!/bin/bash

export PATH="$HOME/arm-linux-androideabi-4.9/bin:$PATH"

# route the compiler (target + host) through ccache to speed up rebuilds.
# only CC/HOSTCC are wrapped; CROSS_COMPILE stays plain so ld/ar/objcopy are not
# passed through ccache (ccache only understands compiler invocations).
#
# use cctv18's ccache-ECS build (https://github.com/cctv18/ccache-ECS) if present,
# falling back to whatever ccache is on PATH. To use the ECS remote cache, also
# export CCACHE_REMOTE_STORAGE before running this script.
CROSS_COMPILE=arm-linux-androideabi-
CCACHE_BIN="$HOME/ccache-ECS/ccache"
[ -x "$CCACHE_BIN" ] || CCACHE_BIN="$(command -v ccache)"
if [ -n "$CCACHE_BIN" ] && [ -x "$CCACHE_BIN" ]; then
	export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
	CC="$CCACHE_BIN ${CROSS_COMPILE}gcc"
	HOSTCC="$CCACHE_BIN gcc"
else
	CC="${CROSS_COMPILE}gcc"
	HOSTCC="gcc"
fi

DEFCONFIG_FILE=$1
if [ -z "$DEFCONFIG_FILE" ]; then
	echo "Need defconfig file(j1v-perf_defconfig)!"
	exit -1
fi

if [ ! -e arch/arm/configs/$DEFCONFIG_FILE ]; then
	echo "No such file : arch/arm/configs/$DEFCONFIG_FILE"
	exit -1
fi

# make .config
env KCONFIG_NOTIMESTAMP=true \
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- ${DEFCONFIG_FILE}

# run menuconfig
env KCONFIG_NOTIMESTAMP=true \
make menuconfig ARCH=arm

make savedefconfig ARCH=arm
# copy .config to defconfig
mv defconfig arch/arm/configs/${DEFCONFIG_FILE}
# clean kernel object
make mrproper
make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" ${DEFCONFIG_FILE}
make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" HOSTCC="$HOSTCC" -j$(nproc)

# package ak3
cp ./arch/arm/boot/zImage ./AnyKernel3
cd AnyKernel3&&zip -r9 ak3.zip * -x .git README.md *placeholder
