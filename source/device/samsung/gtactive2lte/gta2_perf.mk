# Galaxy Tab Active2 LTE: performance and memory properties
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lmk.use_psi=true \
    ro.lmk.use_minfree_levels=false \
    ro.lmk.kill_heaviest_task=true \
    ro.lmk.kill_timeout_ms=100 \
    ro.lmk.swap_free_low_percentage=10 \
    ro.lmk.thrashing_limit=30 \
    ro.lmk.thrashing_limit_decay=50 \
    ro.lmk.critical_upgrade=true \
    ro.lmk.upgrade_pressure=40 \
    ro.lmk.downgrade_pressure=60 \
    dalvik.vm.systemuicompilerfilter=speed \
    dalvik.vm.usejit=true \
    dalvik.vm.madvise.vdexfile.size=31457280 \
    dalvik.vm.madvise.odexfile.size=31457280 \
    dalvik.vm.madvise.artfile.size=0 \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.install=speed-profile \
    ro.sys.fw.bg_apps_limit=24 \
    persist.sys.purgeable_assets=1 \
    ro.config.max_starting_bg=6 \
    media.stagefright.thumbnail.prefer_hw_codecs=true \
    debug.stagefright.omx_default_rank=0 \
    debug.stagefright.omx_default_rank.sw-audio=1 \
    persist.sys.disable_rescue=true

# panel is mounted 180 degrees; renderer (blur is disabled in universal7870-common vendor_prop.mk)
PRODUCT_VENDOR_PROPERTIES += \
    ro.surface_flinger.primary_display_orientation=ORIENTATION_180 \
    debug.hwui.renderer=skiagl

# Tier 1 (benchmarked 2026-11-14): GLES RenderEngine, triple buffering, dex2oat threads, no traced
PRODUCT_VENDOR_PROPERTIES += \
    debug.renderengine.backend=gles \
    ro.surface_flinger.max_frame_buffer_acquired_buffers=3 \
    dalvik.vm.dex2oat-threads=4 \
    persist.traced.enable=0
