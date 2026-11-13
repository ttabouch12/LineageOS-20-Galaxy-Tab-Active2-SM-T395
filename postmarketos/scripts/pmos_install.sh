#!/bin/bash
exec > ~/pmos_install.log 2>&1
set -x
export PATH=$HOME/.local/bin:$PATH
pmbootstrap shutdown
pmbootstrap -y install --password gta2lab --split && echo SPLIT_OK
R=~/pmwork/chroot_native/home/pmos/rootfs
ls -la $R
B=$R/samsung-exynos7-boot.img; T=$R/samsung-exynos7-root.img
[ -f "$B" ] && [ -f "$T" ] || { echo "SPLIT_IMAGES_MISSING"; exit 1; }
OUT=~/gta2lab.img
BS=$(stat -c %s $B); RS=$(stat -c %s $T)
# GPT: 1 MiB alignment, ESP (pmOS_boot) + Linux root (pmOS_root)
BSEC=$(( (BS+511)/512 )); RSEC=$(( (RS+511)/512 ))
TOTAL=$(( 2048 + BSEC + 2048 + RSEC + 2048 + 4096 ))
rm -f $OUT; truncate -s $(( TOTAL*512 )) $OUT
P2=$(( (2048+BSEC+2047)/2048*2048 ))
sfdisk $OUT <<SF
label: gpt
start=2048, size=$BSEC, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="pmOS_boot"
start=$P2, size=$RSEC, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="pmOS_root"
SF
dd if=$B of=$OUT bs=512 seek=2048 conv=notrunc,sparse status=none
dd if=$T of=$OUT bs=512 seek=$P2 conv=notrunc,sparse status=none
sfdisk -l $OUT
file -s $B $T
command -v img2simg >/dev/null && img2simg $OUT ~/gta2lab.simg && ls -la ~/gta2lab.simg
ls -la $OUT; echo IMAGE_OK
