package org.gta2.audiotest;

import android.app.Activity;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.*;

/** Manual stereo check: Left / Right / Both / Stop. Tones loop until Stop. Intent extra "mode" = left|right|both starts directly. */
public class Main extends Activity {
    volatile int mode = -1;   // -1 stop, 0 left, 1 right, 2 both
    volatile boolean alive = true;
    TextView status;

    Button btn(String s, int m) {
        Button b = new Button(this); b.setText(s); b.setTextSize(24); b.setAllCaps(false);
        b.setOnClickListener(v -> set(m)); return b;
    }
    void set(int m) {
        mode = m;
        status.setText(m == 0 ? "Playing LEFT (low tone 330 Hz)" : m == 1 ? "Playing RIGHT (high tone 880 Hz)" : m == 2 ? "Playing BOTH (low left + high right)" : "Stopped");
    }
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        LinearLayout l = new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); l.setPadding(40, 60, 40, 40);
        TextView title = new TextView(this); title.setText("Stereo Test"); title.setTextSize(30); l.addView(title);
        status = new TextView(this); status.setTextSize(20); status.setPadding(0, 20, 0, 30); l.addView(status);
        l.addView(btn("Left", 0)); l.addView(btn("Right", 1)); l.addView(btn("Both", 2)); l.addView(btn("Stop", -1));
        setContentView(l);
        String m = getIntent().getStringExtra("mode");
        set("left".equals(m) ? 0 : "right".equals(m) ? 1 : "both".equals(m) ? 2 : -1);
        new Thread(this::loop).start();
    }
    @Override protected void onDestroy() { alive = false; super.onDestroy(); }
    void loop() {
        int sr = 48000, n = sr / 10;
        AudioTrack at = new AudioTrack.Builder()
            .setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
            .setAudioFormat(new AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT).setSampleRate(sr).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).build())
            .setTransferMode(AudioTrack.MODE_STREAM).setBufferSizeInBytes(sr).build();
        at.play();
        long ph = 0; short[] buf = new short[n * 2];
        while (alive) {
            int m = mode;
            for (int i = 0; i < n; i++, ph++) {
                short lo = (short) (12000 * Math.sin(2 * Math.PI * 330 * ph / sr));
                short hi = (short) (12000 * Math.sin(2 * Math.PI * 880 * ph / sr));
                buf[2 * i] = (m == 0 || m == 2) ? lo : 0;
                buf[2 * i + 1] = (m == 1 || m == 2) ? hi : 0;
            }
            at.write(buf, 0, buf.length);
        }
        at.stop(); at.release();
    }
}
