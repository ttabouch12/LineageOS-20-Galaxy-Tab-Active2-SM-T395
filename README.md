# Samsung Galaxy Tab Active2 LTE (SM-T395 / `gtactive2lte`): custom OS work

Community ports for the Galaxy Tab Active2 LTE (Exynos 7870, Mali-T830, 3 GB RAM, 8" 800x1280).

| Folder | What | Status |
| --- | --- | --- |
| [`android13/`](android13/) | LineageOS 20 (Android 13), 64-bit, microG, Aurora/Orion Store, Magisk-ready, tested CPU 1794 / GPU 1300 MHz overclock, Performance app, F2FS | ✅ daily-usable, zip in [Releases](../../releases) |
| [`postmarketos/`](postmarketos/) | postmarketOS + U-Boot on the mainline Exynos 7870 kernel | 🧪 boots to console; USB networking not working yet |

Everything uses the **stock partition table**, so flashing the stock Samsung
firmware with Odin always takes you back. Stock firmware: [samfw.com](https://samfw.com/firmware/SM-T395).

Proprietary Samsung files are **not** included here; the build instructions say
how to extract them from the stock firmware.

Contributions, test reports and fixes are very welcome. Open an issue or a PR.

License: our scripts and docs are MIT (see `LICENSE`); device trees and kernel
patches keep the license of the project they come from (GPL-2.0 / Apache-2.0).
