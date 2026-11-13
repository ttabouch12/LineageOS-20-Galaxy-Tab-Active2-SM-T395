#
# Copyright (C) 2019 The lineageOS Project
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
#

# Inherit from those products. Most specific first.
# $(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_m.mk)
# this is save to assume since devices like a6lte lauched with o
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_o.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from gtactive2lte device
$(call inherit-product, device/samsung/gtactive2lte/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# microG, app stores (vendor/gta2extra)
$(call inherit-product-if-exists, vendor/gta2extra/config.mk)

# Device identifier. This must come after all inclusions

PRODUCT_NAME := lineage_gtactive2lte
PRODUCT_DEVICE := gtactive2lte
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-T395
PRODUCT_MANUFACTURER := samsung

BUILD_FINGERPRINT := "samsung/gtactive2ltexx/gtactive2lte:9/PPR1.180610.011/T395XXSDCUI7:user/release-keys"

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=gtactive2ltexx \
    PRIVATE_BUILD_DESC="gtactive2ltexx-user 9 PPR1.180610.011 T395XXSDCUI7 release-keys"

PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.PDA=T395XXSDCUI7

TARGET_SUPPORTS_BLUR := false
TARGET_FACE_UNLOCK_SUPPORTED := false

TARGET_VENDOR := samsung
PRODUCT_GMS_CLIENTID_BASE := android-samsung

TARGET_BOOT_ANIMATION_RES := 800
TARGET_GAPPS_ARCH := arm64
