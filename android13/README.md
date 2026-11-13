# LineageOS 20 (Android 13) for the Galaxy Tab Active2 LTE

🚧 **Work in progress.** The first build is compiling; the device tree, patches,
flashing kit and install guide will be added here once it boots on real hardware.

Planned / in the build:
- 64-bit Android 13 on the community `samsungexynos7870` lineage-20 trees (a3y17lte base)
- Hardware video decoding (Exynos OMX), hardware-accelerated UI (Mali-T830)
- QCA9377 Wi-Fi/BT, TFA9890 speaker amp, S5K4H5YC/S5K5E3 cameras, sensors, RIL (data/calls/SMS)
- Stock PIT: CACHE is used as `/vendor`, HIDDEN as `/cache`
- microG (signature spoofing), Aurora Store, Orion Store; Magisk flashable
- Low-RAM tuning (zram, LMK, dalvik), Wacom S Pen kernel fixes from the Android 17 port
