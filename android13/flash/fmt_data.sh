D=/dev/block/platform/13540000.dwmmc0/by-name/USERDATA
umount -l /sdcard 2>/dev/null; umount -l /data 2>/dev/null; sleep 1
M=$(command -v mkfs.f2fs || command -v make_f2fs); echo "f2fs tool: $M"
if [ -n "$M" ]; then $M -f $D 2>&1 | tail -3 || $M $D 2>&1 | tail -3; else echo "no f2fs tool: zeroing header, Android will format f2fs on boot"; dd if=/dev/zero of=$D bs=1048576 count=64 2>&1 | tail -1; fi
blkid $D 2>/dev/null; sync
