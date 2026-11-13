package org.gta2.perf;

import android.app.Service;
import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.IBinder;

/** Watches the foreground app and applies its per-app profile; falls back to the base profile. */
public class PerAppService extends Service {
    final Handler h = new Handler();
    String lastPkg = ""; int lastApplied = -1;
    @Override public IBinder onBind(Intent i) { return null; }
    @Override public int onStartCommand(Intent i, int f, int id) { h.removeCallbacks(tick); h.post(tick); return START_STICKY; }
    final Runnable tick = new Runnable() { public void run() { check(); h.postDelayed(this, 1500); } };
    void check() {
        SharedPreferences sp = getSharedPreferences("apps", MODE_PRIVATE);
        if (sp.getAll().isEmpty()) { lastApplied = -1; return; }
        UsageStatsManager um = (UsageStatsManager) getSystemService(USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        UsageEvents ev = um.queryEvents(now - 10000, now); UsageEvents.Event e = new UsageEvents.Event();
        String pkg = null;
        while (ev.hasNextEvent()) { ev.getNextEvent(e); if (e.getEventType() == UsageEvents.Event.ACTIVITY_RESUMED) pkg = e.getPackageName(); }
        if (pkg == null || pkg.equals(lastPkg)) return;
        lastPkg = pkg;
        int want = sp.getInt(pkg, -1); if (want < 0) want = Perf.baseIndex();
        if (want != lastApplied) { Perf.applyValues(want); lastApplied = want; }
    }
}
