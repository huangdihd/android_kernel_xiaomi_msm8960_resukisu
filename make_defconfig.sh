#!/bin/bash

export PATH="$HOME/arm-linux-androideabi-4.9/bin:$PATH"
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
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- ${DEFCONFIG_FILE}
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- -j$(nproc)

# package ak3
cp ./arch/arm/boot/zImage ./AnyKernel3
cd AnyKernel3&&zip -r9 ak3.zip * -x .git README.md *placeholder
