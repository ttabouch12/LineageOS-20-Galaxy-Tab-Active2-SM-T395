package org.gta2.gpustress;

import android.app.Activity;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import java.nio.*;
import java.util.zip.CRC32;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/** Deterministic heavy fragment shader into a 512x512 FBO; logs a CRC of the pixels for every frame. */
public class Main extends Activity implements GLSurfaceView.Renderer {
    static final String TAG = "GPUSTRESS";
    static final int W = 512, H = 512;
    GLSurfaceView v; int prog, fbo, tex, frame; ByteBuffer px; FloatBuffer quad;
    static final String VS = "attribute vec2 p; varying vec2 uv; void main(){ uv=p*0.5+0.5; gl_Position=vec4(p,0.0,1.0);}";
    static final String FS = "precision highp float; varying vec2 uv; uniform float seed;\n" +
        "void main(){ vec2 z=uv*2.0-1.0; vec3 c=vec3(0.0); float a=seed;\n" +
        " for(int i=0;i<160;i++){ z=vec2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y)*0.5+vec2(sin(a+uv.x*3.1), cos(a*1.3+uv.y*2.7))*0.6;\n" +
        "   a+=0.017*dot(z,z); c+=abs(vec3(sin(z.x*4.0+a), cos(z.y*5.0-a), sin(a*0.7+z.x*z.y)))*0.01; }\n" +
        " gl_FragColor=vec4(fract(c),1.0);}";

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON | WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED | WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
        v = new GLSurfaceView(this); v.setEGLContextClientVersion(2); v.setRenderer(this); setContentView(v);
    }
    @Override protected void onPause() { super.onPause(); v.onPause(); }
    @Override protected void onResume() { super.onResume(); v.onResume(); }

    int sh(int t, String s) { int x = GLES20.glCreateShader(t); GLES20.glShaderSource(x, s); GLES20.glCompileShader(x);
        Log.i(TAG, "shader log: " + GLES20.glGetShaderInfoLog(x)); return x; }

    public void onSurfaceCreated(GL10 g, EGLConfig c) {
        prog = GLES20.glCreateProgram();
        GLES20.glAttachShader(prog, sh(GLES20.GL_VERTEX_SHADER, VS)); GLES20.glAttachShader(prog, sh(GLES20.GL_FRAGMENT_SHADER, FS));
        GLES20.glBindAttribLocation(prog, 0, "p"); GLES20.glLinkProgram(prog);
        int[] t = new int[1]; GLES20.glGenTextures(1, t, 0); tex = t[0];
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex);
        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, W, H, 0, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES20.glGenFramebuffers(1, t, 0); fbo = t[0];
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fbo);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D, tex, 0);
        px = ByteBuffer.allocateDirect(W * H * 4);
        quad = ByteBuffer.allocateDirect(32).order(ByteOrder.nativeOrder()).asFloatBuffer();
        quad.put(new float[]{-1,-1, 1,-1, -1,1, 1,1}).position(0);
        Log.i(TAG, "start " + GLES20.glGetString(GLES20.GL_RENDERER));
    }
    public void onSurfaceChanged(GL10 g, int w, int h) { }
    public void onDrawFrame(GL10 g) {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fbo); GLES20.glViewport(0, 0, W, H);
        GLES20.glUseProgram(prog);
        GLES20.glUniform1f(GLES20.glGetUniformLocation(prog, "seed"), 1.2345f);  // same image every frame
        GLES20.glVertexAttribPointer(0, 2, GLES20.GL_FLOAT, false, 0, quad); GLES20.glEnableVertexAttribArray(0);
        for (int k = 0; k < 4; k++) GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        px.position(0); GLES20.glReadPixels(0, 0, W, H, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, px);
        CRC32 crc = new CRC32(); byte[] a = new byte[W * H * 4]; px.position(0); px.get(a); crc.update(a);
        Log.i(TAG, "frame " + (frame++) + " crc " + Long.toHexString(crc.getValue()));
        // show it on screen too (keeps the compositor busy like a game)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0); GLES20.glClearColor((frame % 60) / 60f, 0.2f, 0.4f, 1f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
    }
}
