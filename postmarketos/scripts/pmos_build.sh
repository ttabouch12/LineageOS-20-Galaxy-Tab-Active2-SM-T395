#!/bin/bash
# runs as builder
exec > ~/pmos_build.log 2>&1
set -x
export PATH=$HOME/.local/bin:$PATH
mkdir -p ~/.ssh ~/.config ~/pmwork
cp ~/id_gta2build.pub ~/.ssh/id_ed25519.pub
cat > ~/.config/pmbootstrap_v3.cfg <<CFG
[pmbootstrap]
aports = /home/builder/pmaports
work = /home/builder/pmwork
device = samsung-exynos7
kernel = exynos7870
ui = console
user = user
hostname = gta2lab
timezone = UTC
locale = en_US.UTF-8
keymap =
extra_packages = openssh-server,htop,nano,wpa_supplicant,iw,networkmanager-cli,linux-firmware-ath10k,linux-firmware-qca
ssh_keys = True
ssh_key_glob = ~/.ssh/id_*.pub
is_default_channel = False
jobs = 6
CFG
# --- add our device tree + wifi drivers to the close-to-mainline kernel package
K=~/pmaports/device/testing/linux-postmarketos-exynos7870
cp ~/exynos7870-gtactive2lte.dts $K/
cd $K
grep -q gtactive2lte APKBUILD || {
  sed -i 's/^\t\$_config$/\t$_config\n\texynos7870-gtactive2lte.dts/' APKBUILD
  sed -i 's#^\tmakefile="\$builddir/arch/arm64/boot/dts/exynos/Makefile"#\tcp "$srcdir/exynos7870-gtactive2lte.dts" arch/arm64/boot/dts/exynos/\n\techo "dtb-\\$(CONFIG_ARCH_EXYNOS) += exynos7870-gtactive2lte.dtb" >> arch/arm64/boot/dts/exynos/Makefile\n\n&#' APKBUILD
  sed -i 's/^pkgrel=\([0-9]*\)/pkgrel=\1/' APKBUILD
}
C=config-postmarketos-exynos7870.aarch64
for o in ATH10K=m ATH10K_SDIO=m ATH_COMMON=m BT_HCIUART=m BT_HCIUART_QCA=y BT_HCIUART_SERDEV=y BT_QCA=m; do
  n=${o%%=*}; sed -i "/^# CONFIG_$n is not set/d;/^CONFIG_$n=/d" $C; echo "CONFIG_$o" >> $C; done
grep -n -E 'gtactive2lte' APKBUILD
cd ~
yes '' | timeout 600 pmbootstrap init
pmbootstrap config
pmbootstrap checksum linux-postmarketos-exynos7870
pmbootstrap -y build --force --arch aarch64 linux-postmarketos-exynos7870 && echo KERNEL_BUILD_OK
pmbootstrap -y install --password gta2lab && echo INSTALL_OK
pmbootstrap export /home/builder/pmos-export || true
ls -la /home/builder/pmos-export/ 2>/dev/null
echo PMOS_BUILD_FINISHED
