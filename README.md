# LineageOS 20 (Android 13) for the Galaxy Tab Active2 LTE (SM-T395) — OC edition

Unofficial LineageOS 20 for `gtactive2lte`, tuned for speed on the Exynos 7870, with a tested
CPU/GPU overclock, a built-in **Performance** app and a long list of hardware fixes.

**Download:** see [Releases](../../releases) → `lineage-20.0-20261113-gtactive2lte-OC-FINAL.zip` (+ `.md5sum`).

> Also for this tablet: **[postmarketOS port](https://github.com/ttabouch12/postmarketOS-Galaxy-Tab-Active2-SM-T395)** (mainline Linux, experimental).
> Stock firmware to go back: [SamFw](https://samfw.com/firmware/SM-T395) (flash with Odin).

## Status

| Works | Notes |
|---|---|
| Display, touch, S Pen, rotation | panel is mounted 180°: fixed with `primary_display_orientation` |
| Hardware keys (Home / Back / Recents) | `gpio_keys.kl` (Recents = key 254); no on-screen bar or taskbar |
| Wi-Fi (QCA9377) | needed `gBpfFilterEnable=0` (APF offload dropped all RX) |
| Bluetooth, mobile data, calls, SMS | |
| Speaker + **earpiece together** | optional, toggle in the Performance app |
| Headphones, mic, camera, sensors, GPS | |
| Hardware video decode (HEVC/H.264) | Exynos MFC via OMX |
| microG, Aurora Store, Orion Store, Magisk | |
| `/data` on **F2FS** | created automatically on first boot |

Not possible on this hardware: **double-tap to wake** (the touch firmware has no gesture
support), **video out over USB-C** (no DisplayPort/HDMI in the SoC; use a DisplayLink adapter +
DisplayLink Presenter app), CPU above 1794 MHz (resets under 8-core load).

## What was fixed / tuned (vs. a plain port)

- **All 8 cores**: Samsung `cpuhotplug` kept cores 4-7 offline → disabled.
- **Power HAL** (`powerhint.json` from the A3 phone) capped the CPU at 1352 MHz for 5 s on every
  app launch and the GPU at 728 MHz under "expensive rendering" → caps removed, boosts kept.
- **Blur** enabled on a single-core Mali-T830 → off. `skiagl` renderer, GPU *Booster* governor,
  memory bus 902 MHz, `noop` I/O, both CPU clusters tuned, zram.
- **Audio**: the HAL rejected 143 gain lines (stereo controls given one value) → fixed, so
  Samsung's headphone/earpiece/call levels now load; louder media curve; earpiece path.
- **Wi-Fi** no internet (APF), **Recents key**, **rotation/touch** (180° panel),
  **IKeyDisabler watchdog boot loop** (touch HAL removed), taskbar hidden for hardware keys.
- **Debloat**: Updater, Seedvault, Easter egg, screensavers, printing, live wallpapers, FlipFlap,
  DSU, IMS entitlement removed; AdServices / on-device personalisation disabled.

## Overclock (tested on the device)

The kernel exposes the Exynos 7870's ECT levels and lets you set voltages live
(`/sys/power/gta2_cpu_volt`, `/sys/devices/11400000.mali/gta2_gpu_volt`). Results with an
error-checking load (8 workers verifying a 32 MB checksum; GPU frames verified by CRC):

| | Stock | Shipped max | Voltage used | Lowest stable | Limit found |
|---|---|---|---|---|---|
| CPU (8×A53) | 1586 MHz | **1794 MHz** (+13%) | 1.0875 V | 1.050 V | 1924 MHz resets under 8-core load at 1.15–1.275 V |
| GPU (Mali-T830) | 1001 MHz | **1300 MHz** (+30%) | 1.0625 V | 1.000 V | 1300 is the top ECT level; 0.9625 V → 93 faults |
| Memory (MIF) | 902 MHz | 902 MHz | — | — | no higher level; not overclocked |

- The kernel never *boots* above 1690 MHz; higher speeds are only applied by the profile you pick.
- Thermal: the first throttle step now keeps 1794 MHz until 81 °C (was 1586 MHz at 76 °C).
- Your chip may differ (ASV group). If you see freezes or reboots, use the Performance profile.

## Performance app (built in)

Profiles: **Battery** (1248/728), **Balanced** (stock), **Performance** (1690/1246, default),
**Max** (1794/1300). Plus: Quick Settings tile, **per-app profiles** (e.g. games on Max),
**charge limit 80 %** (resumes at 75 %), double-tap status bar to sleep, glove mode,
earpiece + speaker and earpiece boost, live CPU/GPU/temperature/battery readout.
Settings are system properties applied by init as root (`init.gta2.perf.rc`), so no root app is needed.

## Install

**Clean install (erases everything):** TWRP for `gtactive2lte` required.
1. Put `FLASH_ANDROID13.bat`, `fmt_data.sh`, the ROM zip and (optionally) `Magisk-v31.1.zip`
   in one folder with `platform-tools`.
2. Boot TWRP (power off, hold Volume Up + Home + Power), plug in, run `FLASH_ANDROID13.bat`.
3. First boot takes 5-10 min (data is formatted as F2FS, apps are optimised).

**Update from an earlier build of this ROM (keeps data):** run `flash/UPDATE_ANDROID13.bat`
with the tablet booted and USB debugging on. Re-flash Magisk afterwards (the script does it).

## Build from source

`source/` contains everything that is not a proprietary blob:
- `device/samsung/gtactive2lte` — full device tree (rc, fstab, audio, keys, power, overlays)
- `patches/` — diffs against the upstream lineage-20 branches: kernel (OC, voltage tables,
  thermal, charge limit, earpiece switch, touch), `universal7870-common`, microG signature spoofing
  (`frameworks_base`, `packages_modules_Permission`), vendor radio fix
- `vendor/` — makefiles; blobs come from the stock firmware (`proprietary-files-list.txt`)
- `local_manifest.xml`, `scripts/` (build, manual packaging, OTA, kernel-only build, boot repack)

```
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
cp local_manifest.xml .repo/local_manifests/ && repo sync -j8
# apply patches/ to the matching projects, copy device/ and vendor/ in, extract blobs
source build/envsetup.sh && lunch lineage_gtactive2lte-userdebug && m bacon -j4
```
16 GB RAM recommended (soong analysis needs ~14 GB). `apps/` holds the Performance, GPU stress
and stereo test apps (built with `javac` + `d8` + `aapt2`, see `apps/*/build.sh`).

## Credits & sources

- [LineageOS](https://lineageos.org) — the OS
- [samsungexynos7870](https://github.com/samsungexynos7870) — community device/kernel trees this port is based on (a3y17lte, universal7870-common)
- [lineageos4microg](https://github.com/lineageos4microg) — signature spoofing patches; [microG](https://github.com/microg/GmsCore)
- [Aurora Store](https://gitlab.com/AuroraOSS/AuroraStore), Orion Store, [Lawnchair](https://github.com/LawnchairLauncher/lawnchair)
- [Magisk](https://github.com/topjohnwu/Magisk), [TWRP](https://twrp.me)
- Stock firmware T395JXSDCUJ1 (TUR) from [SamFw](https://samfw.com) for blobs and the PIT

Use at your own risk. Overclocking can make a device unstable; nothing here changes the bootloader.
