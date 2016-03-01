#!/bin/bash

BASE_F4K_VER="linaro_kernel_0.0.8"

case "$1" in
        spr)
            VARIANT="spr"
            VER=""
            ;;

        *)
            VARIANT="spr"
            VER=""
esac

BASE_F4K_VER=$BASE_F4K_VER-$VARIANT
F4K_VER=$BASE_F4K_VER$VER

export LOCALVERSION="-"`echo $F4K_VER`
export CROSS_COMPILE=/home/lilferraro/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.4-2015.06/bin/arm-cortex_a15-linux-gnueabihf-
export ARCH=arm
export KBUILD_BUILD_USER=lilferraro
export KBUILD_BUILD_HOST="gnome.1x64"

echo
echo "Making bliss_defconfig"

DATE_START=$(date +"%s")

make VARIANT_DEFCONFIG=msm8930_lt02_$VARIANT"_defconfig" bliss_defconfig SELINUX_DEFCONFIG=selinux_defconfig

INIT_DIR=../ramdisks_lp
MODULES_DIR=../filesdir/$VARIANT/lib/modules
KERNEL_DIR=`pwd`
OUTPUT_DIR=../output/$VARIANT
CWM_DIR=../filesdir/cwm_lp
CWM_ANY_DIR=../filesdir/cwm_any

echo
echo "Removing old kernels files"
if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	rm $CWM_DIR/boot.img
	rm $CWM_ANY_DIR/zImage
	rm arch/arm/boot/zImage
else
	echo "No old kernels found"
fi

echo
echo "Removing old modules"
rm -R `find $KERNEL_DIR -name '*.ko'`
rm `echo $MODULES_DIR"/*"`
rm `echo $CWM_DIR/system/lib/modules/"*.ko"`

echo
echo "LOCALVERSION="$LOCALVERSION
echo "CROSS_COMPILE="$CROSS_COMPILE
echo "ARCH="$ARCH
echo "INIT_DIR="$INIT_DIR
echo "MODULES_DIR="$MODULES_DIR
echo "KERNEL_DIR="$KERNEL_DIR
echo "OUTPUT_DIR="$OUTPUT_DIR
echo "CWM_DIR="$CWM_DIR
echo "CWN_ANY_DIR="$CWM_ANY_DIR

make -j2 > /dev/null

echo
find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
find $MODULES_DIR -name '*.ko' -exec cp -v {} $CWM_DIR"/system/lib/modules/" \;

echo
if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	cp arch/arm/boot/zImage $CWM_ANY_DIR
	cd $INIT_DIR
	./mkbootfs $VARIANT| gzip > $CWM_ANY_DIR/ramdisk.gz
	cd $CWM_ANY_DIR
	./mkbootimg --cmdline 'console = null androidboot.hardware=qcom user_debug=23 androidboot.bootdevice=msm_sdcc.1 androidboot.selinux=permissive' --kernel zImage --ramdisk ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output ../cwm_lp/boot.img
	echo
	echo "Make zip package"
	cd ../cwm_lp
	zip -r `echo $F4K_VER`.zip *
	mv  `echo $F4K_VER`.zip ../$OUTPUT_DIR
	cd ../$OUTPUT_DIR
	echo
	FILE_NAME=$F4K_VER.zip
	FILE_SIZE=$(stat -c%s "$FILE_NAME")
	echo "$F4K_VER.zip size is $FILE_SIZE bytes."
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

cd $KERNEL_DIR

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
