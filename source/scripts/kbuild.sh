cd ~/los20
O=$PWD/out/target/product/gtactive2lte/obj/KERNEL_OBJ
export PATH=$PWD/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$PATH
make -C kernel/samsung/exynos7870 O=$O ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- -j6 Image dtbs 2>&1 | grep -E -B2 -A6 "error|Error" | head -60
ls -la $O/arch/arm64/boot/Image
echo KBUILD_DONE
