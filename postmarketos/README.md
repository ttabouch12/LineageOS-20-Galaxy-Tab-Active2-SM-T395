# postmarketOS on the Samsung Galaxy Tab Active2 LTE (SM-T395, `gtactive2lte`)

> **Status: experimental, early bring-up.** It boots to a text console login on the
> tablet's screen. USB networking and SSH do **not** work yet (see *Known issues*).
> This is a starting point for porters, not a daily driver.

The tablet is an Exynos 7870 device (8x Cortex-A53, Mali-T830 MP1, 3 GB RAM,
800x1280 panel, QCA9377 Wi-Fi/BT, SM5705 PMIC/MUIC). This port uses the
close-to-mainline `linux-postmarketos-exynos7870` kernel and U-Boot
(`exynos-mobile`) chainloaded by Samsung's S-Boot.

## What works / what doesn't

| Part | Status |
| --- | --- |
| U-Boot chainload from S-Boot (flashed to BOOT with Odin) | ✅ works |
| Linux kernel boot, systemd-boot via U-Boot EFI | ✅ works |
| Display (simple-framebuffer, 800x1280) | ✅ works (no GPU acceleration) |
| Console login on screen | ✅ works |
| Hardware keys (power, volume, Back gpc5-0, Recent gpd1-4) | ❓ described in the DT, untested |
| eMMC (rootfs on USERDATA) | ✅ works |
| USB gadget networking / SSH over USB | ❌ SM5705 MUIC is left on UART by S-Boot (see below) |
| Wi-Fi (QCA9377 over SDIO, ath10k_sdio; the DT node is enumerated by SDIO id) | ❓ in the DT and kernel config, untested |
| Touchscreen, S Pen, sound, camera, modem, GPU | ❌ not done |

## Known issues (help wanted)

**USB doesn't enumerate.** S-Boot leaves the SM5705 MUIC switched to UART
(`MANUAL_SW1 = 0x6c`, `CONTROL = 0x00`). The MUIC sits at I²C address `0x25` on
`i2c4` (`@13870000`, pins `gpc1-0/1`). Manual switching is bit 2 of reg `0x02`
cleared, and reg `0x13[7:2]` selects the D-/D+ path (`0x24` = USB). There is also a
mux-select GPIO on `gpc5-1`. The planned fix is in U-Boot: enable `CMD_I2C`, add an
`i2c4` alias and a `preboot` of `i2c dev 4; i2c mw 0x25 0x13 0x24` (and the mux GPIO),
or a small SM5705 MUIC driver in the kernel.

## Files

```
source/u-boot/      exynos7870-gtactive2lte.dts + -u-boot.dtsi  (add to U-Boot dts/upstream/src/arm64/exynos)
source/pmaports/    exynos7870-gtactive2lte.dts + diff for linux-postmarketos-exynos7870 (DT, ath10k, QCA BT options)
scripts/            pmos_build.sh (pmbootstrap build/install), pmos_install.sh, samsparse.py (Samsung sparse helper)
build/              gta2-uboot.tar.md5 - U-Boot for Odin (AP slot -> BOOT)
```

The rootfs image (`gta2lab.img`, ~1.3 GB raw) is attached to the GitHub Release, not the repo.

Device tree highlights (based on `exynos7870-j5y17lte`): memory
`0x40000000/0x3d800000` + `0x80000000/0x80000000`, simple-framebuffer at
`0x67000000`, stock regulator voltages (ldo32 1.8 V, ldo35 2.8 V), QCA Wi-Fi on
`mmc1` with a `vdd_wlan` fixed regulator on `gpf3-0`, reserved `tima`, `cp-init`,
`modem` and `gnss` memory.

## Building

Builds were done in a Debian 13 amd64 LXC container (8 cores, 14 GB RAM).

1. `pipx install pmbootstrap` (or clone it) and clone `pmaports`.
2. Copy `source/pmaports/exynos7870-gtactive2lte.dts` into
   `device/testing/linux-postmarketos-exynos7870/` and apply the diff (it adds
   the dts to the APKBUILD and enables `ATH10K_SDIO`, `BT_HCIUART_QCA`).
3. Run `scripts/pmos_build.sh` (device `samsung-exynos7`, kernel `exynos7870`, UI `console`).
   Loop partitions don't show up inside LXC, so use `pmbootstrap install --split`
   and assemble a GPT image with `sfdisk` + `dd` (see the script).
4. U-Boot: add the two files from `source/u-boot`, build `exynos-mobile_defconfig`,
   set `fdtfile=exynos/exynos7870-gtactive2lte.dtb`, and wrap `u-boot.bin` in a
   boot image with the stock S-Boot header (QCDT/DTBH dt, chip `0x1ebe`).

## Installing

**This wipes the tablet.** Back up first. You can always go back with the stock
firmware from [samfw.com](https://samfw.com/firmware/SM-T395) and Odin.

1. Flash `build/gta2-uboot.tar.md5` in Odin (AP slot). It replaces BOOT.
2. Flash a TWRP for `gtactive2lte` to RECOVERY.
3. Odin can't write the rootfs to USERDATA, so boot TWRP and `dd` the image to
   `/dev/block/platform/13540000.dwmmc0/by-name/USERDATA` over `adb`.
4. Reboot. U-Boot finds the largest partition (USERDATA) and boots systemd-boot.
   Default login: `user` / `gta2lab`. Change the password.

## Credits and sources

- [postmarketOS](https://postmarketos.org) and the [pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports) Exynos 7870 kernel package
- [U-Boot](https://source.denx.de/u-boot/u-boot) and the `exynos-mobile` port for Exynos phones
- The Exynos 7870 mainline community (j5y17lte/a3y17lte device trees this one is based on)
- [samsungexynos7870](https://github.com/samsungexynos7870) for the downstream kernel sources used to read the stock hardware layout
- Stock firmware: [samfw.com](https://samfw.com)

License: device trees are GPL-2.0 (same as the kernel/U-Boot files they come from); scripts MIT.
