# microG (needs the signature spoofing patch in frameworks/base) and app stores
PRODUCT_PACKAGES += \
    GmsCore \
    Companion \
    AuroraStore \
    OrionStore
# Don't bootloop if a privileged app asks for an unlisted permission
PRODUCT_PRODUCT_PROPERTIES += \
    ro.control_privapp_permissions=log
