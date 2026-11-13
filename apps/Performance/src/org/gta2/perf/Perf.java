package org.gta2.perf;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import java.io.*;
import java.lang.reflect.Method;

/** Shared helpers: profiles, system properties (applied by init as root), sysfs reads. */
public final class Perf {
    static final String P = "persist.sys.gta2.";
    // name, cpu_max, cpu_min, gpu_max, gpu_gov(1 Interactive, 3 Booster), mif_min, int_min, hotplug
    static final String[][] PROFILES = {
        {"Battery",     "1248000", "343000",  "728",  "1", "451000", "134000", "1"},
        {"Balanced",    "1586000", "546000",  "1001", "1", "546000", "200000", "0"},
        {"Performance", "1690000", "546000",  "1246", "3", "902000", "400000", "0"},
        {"Max",         "1794000", "1014000", "1300", "3", "902000", "400000", "0"},
    };
    static final String[] DESC = {
        "CPU 1.25 GHz, GPU 728 MHz, idle cores sleep. Longest battery.",
        "Stock speeds: CPU 1.59 GHz, GPU 1001 MHz, all cores on.",
        "CPU 1.69 GHz, GPU 1246 MHz, GPU boost, full bus speed. Default.",
        "Overclock: CPU 1.79 GHz, GPU 1300 MHz. Fastest; throttles above 81 °C.",
    };

    static String getProp(String k, String d) {
        try { Method m = Class.forName("android.os.SystemProperties").getMethod("get", String.class, String.class);
              return (String) m.invoke(null, k, d); } catch (Exception e) { return d; }
    }
    static void setProp(String k, String v) {
        try { if (v.equals(getProp(k, ""))) return;
              Method m = Class.forName("android.os.SystemProperties").getMethod("set", String.class, String.class);
              m.invoke(null, k, v); } catch (Exception e) { }
    }
    static boolean flag(String k, boolean d) { return "1".equals(getProp(P + k, d ? "1" : "0")); }
    static void setFlag(String k, boolean on) { setProp(P + k, on ? "1" : "0"); }

    /** Apply a profile's values (does not change the user's base profile). */
    static void applyValues(int i) {
        String[] p = PROFILES[i];
        setProp(P + "hotplug", p[7]);
        setProp(P + "mif_min", p[5]); setProp(P + "int_min", p[6]);
        setProp(P + "gpu_gov", p[4]); setProp(P + "gpu_max", p[3]);
        if (Integer.parseInt(p[2]) < Integer.parseInt(getProp(P + "cpu_min", "546000"))) {
            setProp(P + "cpu_min", p[2]); setProp(P + "cpu_max", p[1]);
        } else { setProp(P + "cpu_max", p[1]); setProp(P + "cpu_min", p[2]); }
        setProp(P + "active", p[0]);
    }
    static int baseIndex() {
        try { return Integer.parseInt(getProp(P + "base", "2")); } catch (Exception e) { return 2; }
    }
    static void setBase(int i) { setProp(P + "base", "" + i); setProp(P + "profile", PROFILES[i][0]); applyValues(i); }

    static String read(String f) {
        try (BufferedReader r = new BufferedReader(new FileReader(f))) {
            StringBuilder sb = new StringBuilder(); String l;
            while ((l = r.readLine()) != null) sb.append(l).append('\n');
            return sb.toString().trim();
        } catch (Exception e) { return ""; }
    }
    static String mhz(String khz) { try { return (Integer.parseInt(khz.trim()) / 1000) + " MHz"; } catch (Exception e) { return "-"; } }

    /** LineageOS system setting (double tap status bar to sleep). */
    static void setLineage(Context c, String name, String value) {
        try {
            Uri u = Uri.parse("content://lineagesettings/system");
            ContentValues v = new ContentValues(); v.put("name", name); v.put("value", value);
            c.getContentResolver().insert(u, v);
        } catch (Exception e) { }
    }
    static String getLineage(Context c, String name, String d) {
        try (android.database.Cursor cu = c.getContentResolver().query(Uri.parse("content://lineagesettings/system"),
                new String[]{"value"}, "name=?", new String[]{name}, null)) {
            if (cu != null && cu.moveToFirst()) return cu.getString(0);
        } catch (Exception e) { }
        return d;
    }
}
