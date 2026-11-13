/*
 * Copyright (C) 2019-2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */
#include <string>
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>
#include <android-base/properties.h>
#include <android-base/logging.h>
#include "vendor_init.h"

using ::android::base::GetProperty;
using ::android::base::SetProperty;

static void property_override(const std::string& name, const std::string& value) {
    prop_info* pi = (prop_info*)__system_property_find(name.c_str());
    if (pi != nullptr)
        __system_property_update(pi, value.c_str(), value.size());
    else
        __system_property_add(name.c_str(), name.size(), value.c_str(), value.size());
}

static void set_ro(const std::string& key, const std::string& value) {
    for (const char* part : {"", "odm.", "product.", "system.", "system_ext.", "vendor."}) {
        std::string k = key;
        k.insert(std::string("ro.product.").size(), part);
        property_override(k, value);
    }
}

void vendor_load_properties() {
    // Dummy BT MAC, replaced from /efs later
    SetProperty("ro.boot.btmacaddr", "00:00:00:00:00:00");
    set_ro("ro.product.model", "SM-T395");
    set_ro("ro.product.device", "gtactive2lte");
    set_ro("ro.product.name", "gtactive2ltexx");
    // Single SIM tablet
    property_override("ro.multisim.simslotcount", "1");
    property_override("ro.vendor.multisim.simslotcount", "1");
}
