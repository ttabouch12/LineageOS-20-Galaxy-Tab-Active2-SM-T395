#
# Copyright (C) 2019-2023 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DEVICE_PATH := device/samsung/gtactive2lte

# audio type guard
TARGET_DEVICE_HAS_TFA_SEC_AUDIO_HAL := false
TARGET_DEVICE_HAS_SEC_AUDIO_HAL := false
TARGET_DEVICE_HAS_OSS_AUDIO_HAL := true

ifeq ($(TARGET_DEVICE_HAS_TFA_SEC_AUDIO_HAL),true)
TARGET_DEVICE_HAS_TFA_AMP := true
TARGET_DEVICE_HAS_PREBUILT_AUDIO_HAL := true
else ifeq ($(TARGET_DEVICE_HAS_OSS_AUDIO_HAL),true)
TARGET_DEVICE_HAS_TFA_AMP := true
endif

# TFA98xx
TARGET_DEVICE_TFA_MODEL := 9890

# radio type guard
TARGET_DEVICE_HAS_SEC_RIL := true

# gnss type guard
TARGET_DEVICE_HAS_SEC_GNSS := true

# prebuilt slsi
TARGET_DEVICE_HAS_SAMSUNG_SLSI_EXYNOS7870 := false


# Launch Android API level
PRODUCT_SHIPPING_API_LEVEL := 23

# Bootanimation
TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 800

# Graphics
PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_CONFIG := normal large xlarge
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_AAPT_PREBUILT_DPI := hdpi mdpi

# Bluetooth - open-source QCOM (QCA9377) HCI stack:
# generic AOSP bluetooth@1.0 HIDL service driving the source-built
# CAF libbt-vendor (ROME firmware download over UART, see libbt-vendor/)
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service \
    libbt-vendor

# Bluetooth audio
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0.vendor \
    android.hardware.bluetooth.audio-impl \
    android.hardware.bluetooth.audio@2.0-impl \
    audio.bluetooth.default

# Advanced display (mDNIe) settings
PRODUCT_PACKAGES += \
    AdvancedDisplay

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(DEVICE_PATH)/overlay

# Ramdisk
PRODUCT_PACKAGES += \
    init.qca9377_bt.rc \
    mobicore.rc \
    init.wifi_device.rc

# Wifi
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0-service \
    hostapd \
    libcld80211 \
    libwifi-hal \
    libwpa_client \
    wificond \
    wpa_supplicant \
    wpa_supplicant.conf \
    wcnss_filter

#hostpad
PRODUCT_PACKAGES += \
    android.hardware.wifi.hostapd@1.0

#wifi
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.4

# power
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/power/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

#supplicant
PRODUCT_PACKAGES += \
    android.hardware.wifi.supplicant@1.3

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(DEVICE_PATH)/configs/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

ifeq ($(TARGET_DEVICE_HAS_OSS_AUDIO_HAL),true)
# Custom mixer_paths OSS
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/mixer_paths_gta2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml
else
# Custom mixer_paths
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(DEVICE_PATH)/configs/audio/mixer_gains.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_gains.xml
endif

# Tablet: low-memory and graphics tuning, fstab, zram
PRODUCT_PACKAGES += \
    fstab.samsungexynos7870 \
    init.gta2.perf.rc

# Tablet-sized dalvik heap (3 GB RAM)
$(call inherit-product, frameworks/native/build/tablet-7in-hdpi-1024-dalvik-heap.mk)

-include $(DEVICE_PATH)/gta2_perf.mk

# Properties
-include $(DEVICE_PATH)/system_prop.mk

# Inherit from common
$(call inherit-product, device/samsung/universal7870-common/device-common.mk)

# $(call inherit-product, device/samsung/universal7870-common/device-prebuilt_bsp-vndk.mk)

$(call inherit-product-if-exists, vendor/samsung/gtactive2lte/gtactive2lte-vendor.mk)

# gtactive2lte: touchscreen config + hardware key layout (Recents = key 254)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/idc/sec_touchscreen.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/sec_touchscreen.idc \
    $(DEVICE_PATH)/configs/keylayout/gpio_keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio_keys.kl
