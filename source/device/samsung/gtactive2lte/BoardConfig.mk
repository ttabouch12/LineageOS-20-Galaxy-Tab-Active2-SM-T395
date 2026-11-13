#
# Copyright (C) 2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := device/samsung/gtactive2lte

# Audio

# audio type guard
TARGET_BOARD_HAS_TFA_SEC_AUDIO_HAL := false
TARGET_BOARD_HAS_SEC_AUDIO_HAL := false

ifeq ($(TARGET_BOARD_HAS_TFA_SEC_AUDIO_HAL),true)
TARGET_BOARD_HAS_TFA_AMP := true
endif

# sec audio hal
TARGET_BOARD_HAS_EXYNOS7870_SEC_AUDIOHAL := false

TARGET_AUDIOHAL_VARIANT := samsung-exynos7870

# secril
TARGET_SECRIL_VARIANT := samsung-exynos7870

# Audiohal
BOARD_USE_SPKAMP := true

# TFA98xx
TARGET_BOARD_TFA_MODEL := 9890


# Display
TARGET_SCREEN_DENSITY := 213

# Assert
TARGET_OTA_ASSERT_DEVICE := gtactive2lte,gtactive2ltexx,gtactive2ltejx

# Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true
BOARD_HAS_QCA_BT_ROME := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(LOCAL_PATH)/bluetooth

# Kernel
TARGET_KERNEL_CONFIG := exynos7870-gtactive2lte_defconfig

# Device Manifest
DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/configs/manifest.xml

# misc
BUILD_BROKEN_VINTF_PRODUCT_COPY_FILES := true

# Init
TARGET_INIT_VENDOR_LIB := //$(LOCAL_PATH):libinit_gtactive2lte
TARGET_RECOVERY_DEVICE_MODULES := libinit_gtactive2lte

# Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(LOCAL_PATH)/releasetools

# CAMERA
BOARD_BACK_CAMERA_ROTATION := 90
BOARD_FRONT_CAMERA_ROTATION := 270
BOARD_BACK_CAMERA_SENSOR := SENSOR_NAME_S5K4H5YC
BOARD_FRONT_CAMERA_SENSOR := SENSOR_NAME_S5K5E3
BOARD_SECURE_CAMERA_SENSOR := SENSOR_NAME_NOTHING
BOARD_SECURE_CAMERA_ROTATION := 0

BOARD_SECURE_CAMERA_SUPPORT := false
BOARD_CAMERA_DUAL_SUPPORT := false
BOARD_CAMERA2_API_SUPPORT := true
BOARD_CAMERA_SAMSUNG_TN_FEATURE := true
BOARD_CAMERA_HAL3_FEATURE := true

# device sepolicy
BOARD_SEPOLICY_DIRS := $(LOCAL_PATH)/sepolicy

# Wifi
BOARD_HAS_QCOM_WLAN := true
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_P2P := "p2p"
WPA_SUPPLICANT_VERSION := VER_0_8_X
WPA_SUPPLICANT_USE_HIDL := true
WIFI_AVOID_IFACE_RESET_MAC_CHANGE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

# inherit from common
-include device/samsung/universal7870-common/BoardConfigCommon.mk

# inherit from the proprietary version
-include vendor/samsung/gtactive2lte/BoardConfigVendor.mk

# ---- Galaxy Tab Active2 LTE (SM-T395) overrides, after the common tree ----
# Stock PIT, no repartition: SYSTEM 3 GB, CACHE (200 MB) is /vendor,
# HIDDEN (100 MB) is /cache. Flashing stock firmware restores everything.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
BOARD_VENDORIMAGE_PARTITION_SIZE := 209715200
# vendor is ~197 MB: fewer inodes leaves room in the 200 MB CACHE partition
BOARD_VENDORIMAGE_EXTFS_INODE_COUNT := 2048
BOARD_CACHEIMAGE_PARTITION_SIZE := 104857600
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11936989184
TARGET_DEVICE_HAS_OWN_FSTAB := true
TARGET_RECOVERY_FSTAB := device/samsung/gtactive2lte/rootdir/etc/fstab.recovery
# S-Boot board name of the stock T395 boot image
BOARD_MKBOOTIMG_ARGS += --board SRPQE17A011RU
# First public build: permissive until the tablet's vendor policy is audited
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

