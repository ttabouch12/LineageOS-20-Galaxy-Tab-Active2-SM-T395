package org.gta2.perf;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class BootReceiver extends BroadcastReceiver {
    /** One-time ROM setup, run as the system user on the first boot after install. */
    static final String[] SETUP = {
        "content insert --uri content://lineagesettings/system --bind name:s:enable_taskbar --bind value:s:0",
        "pm disable-user --user 0 com.android.adservices.api",
        "pm disable-user --user 0 com.android.ondevicepersonalization.services",
        "pm disable-user --user 0 com.android.printspooler",
        "cmd role add-role-holder --user 0 android.app.role.HOME com.android.launcher3",
        "cmd package compile -m speed -f com.android.launcher3",
    };
    @Override public void onReceive(Context c, Intent i) {
        c.startService(new Intent(c, PerAppService.class));
        final SharedPreferences sp = c.getSharedPreferences("setup", Context.MODE_PRIVATE);
        if (sp.getBoolean("done", false)) return;
        final PendingResult pr = goAsync();
        new Thread(() -> {
            for (String cmd : SETUP) {
                try { Runtime.getRuntime().exec(new String[]{"/system/bin/sh", "-c", cmd}).waitFor(); } catch (Exception e) { }
            }
            sp.edit().putBoolean("done", true).apply();
            pr.finish();
        }).start();
    }
}
