# LineageOS 20 (Android 13) for the Galaxy Tab Active2 LTE (SM-T395) — OC edition

Unofficial LineageOS 20 for `gtactive2lte`, tuned for speed on the Exynos 7870, with a tested
CPU/GPU overclock, a built-in **Performance** app and a long list of hardware fixes.

**Download:** see [Releases](../../releases) → latest `lineage-20.0-20261116-gtactive2lte-OC5.zip` (+ `.md5sum`).

> Also for this tablet: **[postmarketOS port](https://github.com/ttabouch12/postmarketOS-Galaxy-Tab-Active2-SM-T395)** (mainline Linux, experimental).
> Stock firmware to go back: [SamFw](https://samfw.com/firmware/SM-T395) (flash with Odin).

## OC5 (2026-11-16) — kernel, scheduler and toolchain deep-tune

**Results vs OC4** (same automated test: launcher/Settings/shade gfxinfo + TikTok 12-swipe feed):

| Metric | Base ROM | OC4 | OC5 |
|---|---|---|---|
| Launcher jank | 8.95% | 2.3% | 2.3–2.7% |
| Notification shade jank | 20.2% | 8.9% | 5.1–6.0% |
| Settings cold start | ~856 ms | ~729 ms | ~705–720 ms |
| TikTok feed jank | – | 33% | 21–24% |
| TikTok frame p90 / p99 | – | 109 / 400 ms | 57–65 / 125–150 ms |
| TikTok cold start (warm cache) | – | 2.49 s | 1.24–1.40 s |

### Kernel (k22e)
- `-mcpu=cortex-a53`; `SCHED_DEBUG`, audit syscall hooks, SELinux AVC stats, `KALLSYMS_ALL`, `BUGVERBOSE` off (scheduler values hard-coded to Android's 10/3/2 ms); AVC cache 512 -> 2048; stack protector regular; RCU callbacks offloaded (NOCB) and pinned to CPUs 1–3; ARMv8 GHASH crypto on.
- GPU no longer forces CPU min 1586 MHz when GPU ≥ 1001 MHz (from AEON/Phantom 7870 kernels). This removes simultaneous CPU+GPU peak current and makes **1794 MHz stable under full 8-core + GPU load** (falls back to 1690 MHz at ~76 °C).
- Interactive governor patches (scale early, ignore ≤5% load, hispeed delay on target freq); unbound workqueues on CPUs 1–3; grip-sensor debug poll 2 s -> 60 s; display trace markers skipped when not tracing.
- Exynos-snapshot event logging disabled at boot.

### System
- SurfaceFlinger moved from the background cpuset to top-app with real-time FIFO priority; GPU/display/audio IRQs moved off CPU0; `mmcqd`/`rcuo` on CPUs 1–3.
- Fixed CPU cap: profile default now 1794 MHz; touch boost 1690 MHz, launch boost 1794 MHz on both clusters.
- Apps compiled automatically: `dex2oat64`, install-time `speed`, and a boot service that compiles all user apps (`speed`, fallback `speed-profile`) every 6 h while charging.
- jemalloc (no Scudo, no malloc zero-fill), platform-wide ThinLTO, system_server compiled `speed`.
- ART launch prefetch capped to 8 MB; USAP pool 3; perfetto hprof off; INT bus floor 400 MHz; eMMC queue tuning (`iostats=0`, `add_random=0`, `nr_requests=256`, `rq_affinity=2`); swappiness 100; Wi-Fi/BLE always-scan off; animations 0.5×; colour management/HDR paths off; camera not pinned.

### Investigated, not used
- CPU 1924/2002 MHz (power IC current limit), GPU > 1300 MHz (no ECT levels), Mali r29 (no 64-bit blob for 7870), memory bus > 902 MHz (bootloader table), EAS/MGLRU (not feasible on 3.18), cached-app freezer (needs binder freeze), BFQ/ROW (not in tree), stack auto-zero removal (breaks host build tools).

### Notes
- `/data` is **not encrypted** on this ROM.
- SELinux is permissive on the test unit only (boot script); the gain was small, so release builds keep the stock behaviour unless you change it.

## Linux (Ubuntu Touch, Halium 13) — alpha
**Ubuntu Touch 24.04 (Halium 13) port: alpha, boots to Lomiri with Wi-Fi, LTE/SIM, Bluetooth, stereo speakers, mic, sensors, USB networking.** See [`ubuntu-touch/`](ubuntu-touch/README.md) and the `v24.04-ut-gta2-alpha1` release. It reuses this ROM's vendor and OC kernel tree; Android is unaffected.

## OC4 (2026-11-15) — driver-level tuning + 68 Hz panel

### Display
- Panel overclocked 60 -> 68 Hz (DT timing, `refresh = 68`, pixel clock 69 -> 78 MHz).
- DSI link unchanged: 500 MHz x 4 lanes.
- Tested: 63/66 Hz clean but worse frame pacing; 70 Hz small artifacts on the test unit; 75 Hz distorted. 68 Hz is the sweet spot.

### GPU (Mali-T830)
- Wake/start clock 343 -> 545 MHz.
- Shader power-off hysteresis: `pm_poweroff = "400000 25 25"`, so cores don't power-cycle between frames.
- JS scheduling period 50 -> 25 ms; context scheduling mode 1.

### HWC
- `debug.hwc.skip_dma_types` `0,2` -> `2`. Frees one more hardware overlay; the status bar is now composed by display hardware.

### CPU
- Interactive governor `timer_rate` 20 -> 10 ms on both clusters.

### Memory / storage
- `extra_free_kbytes` = 24000.
- eMMC `clkgate_delay` 10 -> 100.

### Compatibility
- Removed false Vulkan 1.1 feature declarations. No Vulkan driver exists for Mali-T830 r28 on this device; apps no longer try Vulkan and fall back to GLES.

### Investigated, not used
- Memory bus: already at 902 MHz max during UI.
- HWUI partial redraw / SF layer caching: slower.
- EAS / LTO: low gain.

### Benchmarks
Same automated test. OC3 = 60 Hz, OC4 = 68 Hz.

| Metric | OC3 | OC4 |
|---|---|---|
| Launcher jank | 6.2% | 2.3% |
| Launcher p50 frame time | 22 ms | 15 ms |
| Launcher frames delivered in test | 514 | 574 (+12%) |
| Settings jank | 2.1% | 0.75% |
| Notification shade jank | 15% | 8.9% |
| Settings cold start | ~720–740 ms | ~720–740 ms (unchanged) |
| Settings warm start | — | ~65–75 ms |

> **Note:** if your panel shows artifacts at 68 Hz, flash the OC3 boot image or report it.

### Flashing
- Zip: `lineage-20.0-20261115-gtactive2lte-OC4.zip`
- Flash in TWRP. Dirty flash over OC3/OC2 is OK.
- Re-flash Magisk afterwards if you use it.

## OC3 (2026-11-14): kernel build + scheduler/memory tuning, benchmarked

Zip: `lineage-20.0-20261114-gtactive2lte-OC3.zip` (release tag `v20.0-oc3-20261114`).

**Kernel** (LineageOS 22.2 exynos7870 base, Linux 3.18.140):
- built with GCC 4.9 at **-O2** (was -Os), **CONFIG_HZ=300** (was 100)
- Samsung debug/log overhead reduced: `MMC_DW_DEBUG`, `CGROUP_DEBUG`, `DETECT_HUNG_TASK` off; Exynos-snapshot freq/clk/regulator/thermal/SMC logging off
- PSI + cpusets + per-CPU zram with LZ4 (8 streams); in-kernel LMK replaced by PSI lmkd
- OC kept: CPU **1794 MHz @ 1.0875 V**, GPU **1300 MHz @ 1.0625 V**, GPU DVFS thresholds retuned

**Userspace:**
- ART heap tuned for 3 GB: `heapminfree=2m`, `heapmaxfree=16m`, `heaptargetutilization=0.7`
- dex2oat pinned to cores 1,2,3,5,6; apps fully compiled on install (`pm.dexopt.install=speed`)
- dirty writeback capped (16 MB background / 64 MB)
- background and system-background cpusets moved off CPU0 (cores 1-3); foreground on 1-7
- camera app no longer pinned in RAM (`pinner.pin_camera=false`)
- power HAL INTERACTION/LAUNCH boosts on both clusters

**Tested and rejected** (made frame times worse): HWUI buffer-age partial redraw, SurfaceFlinger layer caching, GL backpressure.
**Investigated and dropped:** Mali r29p0 (no 64-bit r29 blob exists for the 7870), CPU 1924 MHz (resets under load even at 1.25 V: power-delivery limit), Clang-built kernel (WIP).

UI benchmark (Performance profile):

| | stock-ish baseline | OC2 / k22 | OC3 |
|---|---|---|---|
| launcher jank | 8.95 % | ~6 % | 5.4-6.2 % |
| launcher p99 | 46 ms | 40 ms | 38-40 ms |
| notification shade p50 / p99 | - / 105 ms | 28 / 48-61 ms | 22-28 / 46-61 ms |
| Settings cold start | ~940 ms | ~750 ms | ~706-730 ms |
| Settings warm start | | | ~70 ms |

**Flashing:** same as OC2 (TWRP, see [Install](#install)). A wipe is recommended when coming from non-OC builds; a dirty flash over OC2 is fine.
Re-flash Magisk afterwards if you use it.

## OC2 (2026-11-14): kernel rebase + deep tuning, benchmarked

**Kernel now based on samsungexynos7870 `lineage-22.2`** (commit `b7d1df08`, +1,243 commits over lineage-20), with this ROM's patches on top
(`source/patches/kernel_samsung_exynos7870-on-lineage-22.2.patch`; the old lineage-20 patch is kept as `legacy_...`). It brings and enables:
- **PSI** with the in-kernel low-memory killer removed, so Android 13's lmkd runs in PSI mode (`ro.lmk.use_psi=true`)
- **zram**: per-CPU streams (8 instead of 1), new zsmalloc and LZ4, ZSTD available, no vnswap
- **cpusets**: background work on cores 0-2, foreground app on all 8 cores
- Exynos snapshot IRQ/hook tracing off
- **GPU DVFS fix**: the 1146-1300 MHz steps had 98/100 % thresholds, so the governor never climbed past 1001 MHz; now graded 70/90 to 85/100 and the high-speed jump goes to 1001 MHz. Under load the GPU now holds 1246-1300 MHz.

Userspace (tested one by one, kept only what helped):
- GLES RenderEngine, triple buffering, `dex2oat-threads=4`, traced off, 20 cached apps, USAP pool
- power HAL touch boost on both CPU clusters (1248 MHz) and launch boost (1586 MHz for 5 s)
- `debug.sf.enable_gl_backpressure` was tested and **rejected**: it made the launcher worse

UI benchmark (Performance profile; launcher swipes, Settings scroll, notification shade, cold starts):

| | before | OC2 |
|---|---|---|
| launcher jank / p99 | 8.95 % / 46 ms | 5.5-6.2 % / 40 ms |
| notification shade p99 | 105 ms | 48-53 ms |
| Settings cold start | ~940 ms | ~740 ms |

Researched but skipped as placebo or not applicable here: eMMC "CRC off" tweaks, simple_lmk, extra CPU governors,
DECON partial update (video-mode panel), Vulkan as default renderer.

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
