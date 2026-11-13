package org.gta2.perf;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.*;
import java.util.*;

public class MainActivity extends Activity {
    TextView status, current;
    final Handler h = new Handler();
    final ArrayList<String> cpuFreqs = new ArrayList<>(), gpuFreqs = new ArrayList<>();
    LinearLayout root;

    TextView label(String s, float size, boolean bold) {
        TextView t = new TextView(this); t.setText(s); t.setTextSize(size);
        if (bold) t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setPadding(0, 22, 0, 6); return t;
    }
    Switch sw(String title, String sub, boolean on, CompoundButton.OnCheckedChangeListener l) {
        Switch s = new Switch(this); s.setText(title + "\n" + sub); s.setTextSize(15); s.setChecked(on);
        s.setPadding(0, 14, 0, 14); s.setOnCheckedChangeListener(l); root.addView(s); return s;
    }

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        startService(new Intent(this, PerAppService.class));
        ScrollView sv = new ScrollView(this);
        root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setPadding(40, 30, 40, 60); sv.addView(root);
        root.addView(label("Performance", 26, true));
        current = label("", 15, false); root.addView(current);

        // ---- profiles
        root.addView(label("Profile", 18, true));
        for (int i = 0; i < Perf.PROFILES.length; i++) {
            final int idx = i;
            Button bt = new Button(this); bt.setText(Perf.PROFILES[i][0]); bt.setAllCaps(false); bt.setTextSize(17);
            bt.setOnClickListener(v -> { Perf.setBase(idx); toast(Perf.PROFILES[idx][0] + " applied"); refresh(); });
            TextView d = new TextView(this); d.setText(Perf.DESC[i]); d.setTextSize(13); d.setPadding(12, 0, 0, 12);
            root.addView(bt); root.addView(d);
        }
        TextView tip = new TextView(this); tip.setTextSize(13);
        tip.setText("Tip: add the \"Perf\" tile to Quick Settings to switch profiles from the notification shade.");
        root.addView(tip);

        // ---- custom limits (only tested speeds are offered by the kernel)
        root.addView(label("Custom limits", 18, true));
        for (String f : Perf.read("/sys/power/cpufreq_table").split("\\s+")) if (!f.isEmpty() && Integer.parseInt(f) <= 1794000) cpuFreqs.add(f);
        for (String f : Perf.read("/sys/devices/11400000.mali/dvfs_table").split("\\s+")) if (!f.isEmpty() && Integer.parseInt(f) <= 1300) gpuFreqs.add(f);
        ArrayList<String> cl = new ArrayList<>(), gl = new ArrayList<>();
        for (String f : cpuFreqs) cl.add("CPU max " + Perf.mhz(f));
        for (String f : gpuFreqs) gl.add("GPU max " + f + " MHz");
        final Spinner cpuSpin = new Spinner(this); cpuSpin.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, cl));
        final Spinner gpuSpin = new Spinner(this); gpuSpin.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, gl));
        int ci = cpuFreqs.indexOf(Perf.getProp(Perf.P + "cpu_max", "1690000")); if (ci >= 0) cpuSpin.setSelection(ci);
        int gi = gpuFreqs.indexOf(Perf.getProp(Perf.P + "gpu_max", "1246")); if (gi >= 0) gpuSpin.setSelection(gi);
        root.addView(cpuSpin); root.addView(gpuSpin);
        Button custom = new Button(this); custom.setText("Apply custom limits"); custom.setAllCaps(false);
        custom.setOnClickListener(v -> {
            if (!cpuFreqs.isEmpty()) Perf.setProp(Perf.P + "cpu_max", cpuFreqs.get(cpuSpin.getSelectedItemPosition()));
            if (!gpuFreqs.isEmpty()) Perf.setProp(Perf.P + "gpu_max", gpuFreqs.get(gpuSpin.getSelectedItemPosition()));
            Perf.setProp(Perf.P + "profile", "Custom"); Perf.setProp(Perf.P + "active", "Custom");
            toast("Custom limits applied"); refresh();
        });
        root.addView(custom);

        // ---- features
        root.addView(label("Features", 18, true));
        sw("Charge limit 80%", "Stops charging at 80 % and resumes at 75 %. Best for a tablet that stays plugged in.",
            Perf.flag("chg_limit", false), (v, on) -> Perf.setFlag("chg_limit", on));
        sw("Double-tap to sleep", "Double-tap the status bar to turn the screen off.",
            !"0".equals(Perf.getLineage(this, "double_tap_sleep_gesture", "1")),
            (v, on) -> Perf.setLineage(this, "double_tap_sleep_gesture", on ? "1" : "0"));
        sw("Glove mode", "Higher touch sensitivity, for gloves.",
            Perf.flag("glove", false), (v, on) -> Perf.setFlag("glove", on));
        sw("Earpiece + speaker", "Play media on the earpiece and the speaker together for fuller sound. Applies to the next sound played.",
            Perf.flag("spk_ep", true), (v, on) -> Perf.setFlag("spk_ep", on));
        sw("Earpiece boost", "Louder earpiece (+14 dB instead of +10 dB). May distort at full volume.",
            Perf.flag("ep_boost", false), (v, on) -> Perf.setFlag("ep_boost", on));

        // ---- per-app
        root.addView(label("Per-app profiles", 18, true));
        TextView pd = new TextView(this); pd.setTextSize(13);
        pd.setText("Pick a profile for an app; it switches automatically while that app is open, then returns to your profile.");
        root.addView(pd);
        final SharedPreferences sp = getSharedPreferences("apps", MODE_PRIVATE);
        PackageManager pm = getPackageManager();
        Intent li = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> apps = pm.queryIntentActivities(li, 0);
        final TreeMap<String, String> sorted = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
        for (ResolveInfo r : apps) if (!r.activityInfo.packageName.equals(getPackageName()))
            sorted.put(r.loadLabel(pm).toString() + "\u0000" + r.activityInfo.packageName, r.activityInfo.packageName);
        String[] choices = {"Default", "Battery", "Balanced", "Performance", "Max"};
        for (Map.Entry<String, String> en : sorted.entrySet()) {
            final String pkg = en.getValue();
            LinearLayout row = new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL);
            TextView name = new TextView(this); name.setText(en.getKey().split("\u0000")[0]); name.setTextSize(15);
            name.setLayoutParams(new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
            Spinner s = new Spinner(this); s.setAdapter(new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, choices));
            s.setSelection(sp.getInt(pkg, -1) + 1, false);
            s.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                public void onItemSelected(AdapterView<?> a, View v, int pos, long id) {
                    if (pos == 0) sp.edit().remove(pkg).apply(); else sp.edit().putInt(pkg, pos - 1).apply();
                }
                public void onNothingSelected(AdapterView<?> a) { }
            });
            row.addView(name); row.addView(s); root.addView(row);
        }

        root.addView(label("Live", 18, true));
        status = new TextView(this); status.setTypeface(Typeface.MONOSPACE); status.setTextSize(14);
        root.addView(status);
        root.addView(label("All settings are kept after reboot. The kernel still lowers the speed by itself if the chip gets too hot.", 12, false));
        setContentView(sv);
    }
    void toast(String s) { Toast.makeText(this, s, Toast.LENGTH_SHORT).show(); }

    final Runnable tick = new Runnable() { public void run() { refresh(); h.postDelayed(this, 1000); } };
    @Override protected void onResume() { super.onResume(); h.post(tick); }
    @Override protected void onPause() { super.onPause(); h.removeCallbacks(tick); }

    void refresh() {
        String base = Perf.PROFILES[Perf.baseIndex()][0], act = Perf.getProp(Perf.P + "active", base);
        current.setText("Profile: " + Perf.getProp(Perf.P + "profile", base) + (act.equals(base) ? "" : "   (now: " + act + ")"));
        String c = "/sys/devices/system/cpu/";
        StringBuilder s = new StringBuilder();
        s.append("Cores online : ").append(Perf.read(c + "online")).append('\n');
        s.append("CPU 0-3      : ").append(Perf.mhz(Perf.read(c + "cpu0/cpufreq/scaling_cur_freq")))
         .append("  (max ").append(Perf.mhz(Perf.read(c + "cpu0/cpufreq/scaling_max_freq"))).append(")\n");
        String c4 = Perf.read(c + "cpu4/cpufreq/scaling_cur_freq");
        s.append("CPU 4-7      : ").append(c4.isEmpty() ? "sleeping" : Perf.mhz(c4))
         .append(c4.isEmpty() ? "" : "  (max " + Perf.mhz(Perf.read(c + "cpu4/cpufreq/scaling_max_freq")) + ")").append('\n');
        s.append("GPU          : ").append(Perf.read("/sys/devices/11400000.mali/clock")).append(" MHz  (max ")
         .append(Perf.read("/sys/kernel/gpu/gpu_max_clock")).append(")\n");
        s.append("Memory bus   : ").append(Perf.mhz(Perf.read("/sys/class/devfreq/17000010.devfreq_mif/cur_freq"))).append('\n');
        try { s.append("CPU temp     : ").append(Integer.parseInt(Perf.read("/sys/class/thermal/thermal_zone0/temp")) / 1000).append(" °C\n"); } catch (Exception e) { }
        try { s.append("Battery      : ").append(Perf.read("/sys/class/power_supply/battery/capacity")).append(" %  ")
                .append(Perf.read("/sys/class/power_supply/battery/status")).append('\n'); } catch (Exception e) { }
        status.setText(s.toString());
    }
}
