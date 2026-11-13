import re
K='/home/builder/los20/kernel/samsung/exynos7870/'
def edit(path, fn):
    p=K+path; s=open(p).read(); s2=fn(s)
    if s2==s: print('UNCHANGED',path); return
    open(p,'w').write(s2); print('patched',path)

# 1. charge limit 75-80% (store_mode)
def batt(s):
    if 'gtactive2lte: charge limit' in s: return s
    i=s.index('#define STORE_MODE_CHARGING_MIN 60'); j=s.index('#endif',i)+len('#endif')
    return s[:j]+'\n/* gtactive2lte: charge limit 75-80% when store_mode=1 */\n#undef STORE_MODE_CHARGING_MAX\n#undef STORE_MODE_CHARGING_MIN\n#define STORE_MODE_CHARGING_MAX 80\n#define STORE_MODE_CHARGING_MIN 75\n'+s[j:]
edit('drivers/battery_v2/include/sec_battery.h', batt)

# 2. touch gesture string library
edit('drivers/input/touchscreen/stm/fts_ts.h', lambda s: s.replace('#undef FTS_SUPPORT_STRINGLIB','#define FTS_SUPPORT_STRINGLIB',1))

# 3. thermal: keep 1794 until trip 1, 1586 at trip 1
def dt(s):
    out=[]; blocks=re.split(r'(tmuctrl_[01]: tmuctrl_CPUCL[01]@)', s)
    # rebuild: modify text following each CPU tmu label up to next 'tmuctrl_'
    res=s
    for lab in ('tmuctrl_0: tmuctrl_CPUCL0@','tmuctrl_1: tmuctrl_CPUCL1@'):
        a=res.index(lab); b=res.index('};',a)
        blk=res[a:b]
        nb=blk.replace('freq_clip_max_0 = <1586000>;','freq_clip_max_0 = <1794000>;').replace('freq_clip_max_1 = <1248000>;','freq_clip_max_1 = <1586000>;')
        res=res[:a]+nb+res[b:]
    return res
edit('arch/arm64/boot/dts/exynos7870-gtactive2_common.dtsi', dt)

# 4. codec: earpiece-with-speaker switch + boost
def codec(s):
    if 'gta2_spk_ep' in s: return s
    a='static int epdrv_ev(struct snd_soc_dapm_widget *w,'
    s=s.replace(a,'''/* gtactive2lte: earpiece plays along with the speaker for media.
 * /sys/module/snd_soc_cod3026/parameters/spk_ep   1 = on, 0 = off
 * /sys/module/snd_soc_cod3026/parameters/ep_boost 1 = +14 dB instead of the mixer value
 * "EP Media Switch" is set by the speaker mixer path only. */
static int gta2_spk_ep = 1;
module_param_named(spk_ep, gta2_spk_ep, int, 0644);
static int gta2_ep_boost;
module_param_named(ep_boost, gta2_ep_boost, int, 0644);
static int gta2_ep_media;
static int gta2_ep_media_get(struct snd_kcontrol *kcontrol, struct snd_ctl_elem_value *ucontrol)
{ ucontrol->value.integer.value[0] = gta2_ep_media; return 0; }
static int gta2_ep_media_put(struct snd_kcontrol *kcontrol, struct snd_ctl_elem_value *ucontrol)
{ gta2_ep_media = !!ucontrol->value.integer.value[0]; return 0; }

'''+a,1)
    b='''		snd_soc_update_bits(w->codec, COD3026X_37_MIX_DA2,
				EN_EP_MIX_DCTL_MASK, EN_EP_MIX_DCTL_MASK);

		msleep(136);
'''
    assert s.count(b)==1
    s=s.replace(b,'''		snd_soc_update_bits(w->codec, COD3026X_37_MIX_DA2,
				EN_EP_MIX_DCTL_MASK, EN_EP_MIX_DCTL_MASK);

		if (gta2_ep_media) {
			if (!gta2_spk_ep)
				snd_soc_update_bits(w->codec, COD3026X_37_MIX_DA2,
					EN_EP_MIX_DCTL_MASK | EN_EP_MIX_DCTR_MASK, 0);
			else if (gta2_ep_boost)
				snd_soc_update_bits(w->codec, COD3026X_32_VOL_EP_SPK,
					CTVOL_EP_MASK, 14 << CTVOL_EP_SHIFT);
		}

		msleep(136);
''')
    c='''	SOC_SINGLE_EXT("DAC Soft Mute", SND_SOC_NOPM, 0, 100, 0,
			dac_soft_mute_get, dac_soft_mute_put),
'''
    assert s.count(c)==1
    s=s.replace(c,c+'''	SOC_SINGLE_EXT("EP Media Switch", SND_SOC_NOPM, 0, 1, 0,
			gta2_ep_media_get, gta2_ep_media_put),
''')
    # controls array is defined before epdrv_ev: forward-declare the handlers
    d='static const struct snd_kcontrol_new cod3026x_snd_controls[]'
    if d in s:
        s=s.replace(d,'static int gta2_ep_media_get(struct snd_kcontrol *kcontrol, struct snd_ctl_elem_value *ucontrol);\nstatic int gta2_ep_media_put(struct snd_kcontrol *kcontrol, struct snd_ctl_elem_value *ucontrol);\n'+d,1)
    return s
edit('sound/soc/codecs/cod3026x.c', codec)
print('DONE')
