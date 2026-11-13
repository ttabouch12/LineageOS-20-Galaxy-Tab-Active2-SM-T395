import re,sys
K='/home/builder/los20/kernel/samsung/exynos7870/'
def edit(path, fn):
    p=K+path; s=open(p).read(); s2=fn(s); assert s2!=s, path; open(p,'w').write(s2); print('patched',path)

# 1. ASV caps -> all ECT levels
def asv(s):
    s=re.sub(r'#define GTA2_OC_CPU_MAX \d+','#define GTA2_OC_CPU_MAX 2002000',s)
    s=re.sub(r'#define GTA2_OC_G3D_MAX \d+','#define GTA2_OC_G3D_MAX 1300000',s)
    return s
edit('drivers/soc/samsung/pwrcal/S5E7870/S5E7870-asv.c', asv)

# 2. cpufreq-cal: default voltages for uncalibrated levels, hard ceiling, allow all levels
def cal(s):
    old=s[s.index('			/* gtactive2lte OC: ECT has only a placeholder voltage above 1690 MHz */'):s.index('				ptr->volt_table[i] = 1200000;\n')+len('				ptr->volt_table[i] = 1200000;\n')]
    new='''			/* gtactive2lte OC: ECT has only a placeholder voltage above 1690 MHz.
			 * Start values; tune live via /sys/power/gta2_cpu_volt */
			if (ptr_temp_table[i].rate == 1794000 && ptr->volt_table[i] < 1150000)
				ptr->volt_table[i] = 1150000;
			if (ptr_temp_table[i].rate == 1924000 && ptr->volt_table[i] < 1250000)
				ptr->volt_table[i] = 1250000;
			if (ptr_temp_table[i].rate == 2002000 && ptr->volt_table[i] < 1300000)
				ptr->volt_table[i] = 1300000;
			if (ptr->volt_table[i] > 1300000)
				ptr->volt_table[i] = 1300000;
'''
    s=s.replace(old,new)
    a='''	if (ptr->max_support_idx < cal_max_support_idx)
		ptr->max_support_idx = cal_max_support_idx;
'''
    assert a in s
    s=s.replace(a,a+'''	/* gtactive2lte OC: expose every level CAL allows (boot max is still capped in init) */
	ptr->max_support_idx = cal_max_support_idx;
''')
    return s
edit('drivers/cpufreq/exynos-mp-cpufreq-cal.c', cal)

# 3. cpufreq: safe default policy max + live voltage table
def mp(s):
    a='	return cpufreq_frequency_table_cpuinfo(policy, exynos_info[cur]->freq_table);\n'
    assert s.count(a)==1
    s=s.replace(a,'''	{
		int r = cpufreq_frequency_table_cpuinfo(policy, exynos_info[cur]->freq_table);
		/* gtactive2lte OC: never start above the tested 1690 MHz; raise via scaling_max_freq */
		if (!r && policy->max > 1690000)
			policy->max = 1690000;
		return r;
	}
''')
    b='#ifdef CONFIG_PM\nstatic struct global_attr cpufreq_table =\n'
    assert s.count(b)==1
    s=s.replace(b,'''/* gtactive2lte OC: live CPU voltage table.  read: "freq cl0_uV cl1_uV"
 * write: "freq uV" (both clusters).  Clamped to 600000..1300000, 6250 uV steps. */
static ssize_t show_gta2_cpu_volt(struct kobject *kobj, struct attribute *attr, char *buf)
{
	int i; ssize_t n = 0;
	struct exynos_dvfs_info *a = exynos_info[CL_ZERO], *b = exynos_info[CL_ONE];
	for (i = 0; i < a->max_idx_num; i++)
		n += snprintf(buf + n, PAGE_SIZE - n, "%u %u %u\\n", a->freq_table[i].frequency,
			a->volt_table[i], b ? b->volt_table[i] : 0);
	return n;
}
static ssize_t store_gta2_cpu_volt(struct kobject *kobj, struct attribute *attr,
				const char *buf, size_t count)
{
	unsigned int f, v; int i, c, hit = 0;
	if (sscanf(buf, "%u %u", &f, &v) != 2)
		return -EINVAL;
	if (v < 600000 || v > 1300000)
		return -EINVAL;
	v = (v / 6250) * 6250;
	for (c = CL_ZERO; c <= CL_ONE; c++) {
		struct exynos_dvfs_info *p = exynos_info[c];
		if (!p) continue;
		for (i = 0; i < p->max_idx_num; i++)
			if (p->freq_table[i].frequency == f) { p->volt_table[i] = v; hit = 1; }
	}
	if (!hit) return -EINVAL;
	pr_info("gtactive2lte OC: cpu %u kHz -> %u uV\\n", f, v);
	return count;
}
static struct global_attr gta2_cpu_volt =
		__ATTR(gta2_cpu_volt, S_IRUGO | S_IWUSR, show_gta2_cpu_volt, store_gta2_cpu_volt);

''' + b)
    c='	ret = sysfs_create_file(power_kobj, &cpufreq_table.attr);\n'
    assert s.count(c)==1
    s=s.replace(c,'	if (sysfs_create_file(power_kobj, &gta2_cpu_volt.attr))\n		pr_err("gtactive2lte OC: no gta2_cpu_volt\\n");\n'+c)
    return s
edit('drivers/cpufreq/exynos-mp-cpufreq.c', mp)

# 4. GPU: 1300 level voltage start value
def gov(s):
    a='''				if (dvfs_table[i].clock == 1246 && dvfs_table[i].voltage < 1081250) {'''
    assert a in s
    return s.replace(a,'''				if (dvfs_table[i].clock == 1300 && dvfs_table[i].voltage < 1131250)
					dvfs_table[i].voltage = 1131250;
'''+a)
edit('drivers/gpu/arm/t83x/r28p0/platform/exynos/gpu_dvfs_governor.c', gov)
def ge(s):
    return s.replace('{GPU_MAX_CLOCK, 1246},','{GPU_MAX_CLOCK, 1300},').replace('{GPU_MAX_CLOCK_LIMIT, 1246},','{GPU_MAX_CLOCK_LIMIT, 1300},')
edit('drivers/gpu/arm/t83x/r28p0/platform/exynos/gpu_exynos7870.c', ge)

# 5. GPU live voltage table
def ci(s):
    a='static ssize_t show_asv_table(struct device *dev, struct device_attribute *attr, char *buf)\n'
    assert s.count(a)==1
    s=s.replace(a,'''/* gtactive2lte OC: live GPU voltage table. read "MHz uV"; write "MHz uV" (600000..1200000) */
static ssize_t show_gta2_gpu_volt(struct device *dev, struct device_attribute *attr, char *buf)
{
	int i; ssize_t n = 0;
	struct exynos_context *platform = (struct exynos_context *)pkbdev->platform_context;
	if (!platform) return -ENODEV;
	for (i = 0; i < platform->table_size; i++)
		n += snprintf(buf + n, PAGE_SIZE - n, "%d %d\\n", platform->table[i].clock, platform->table[i].voltage);
	return n;
}
static ssize_t set_gta2_gpu_volt(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
	int i, f, v, hit = 0;
	struct exynos_context *platform = (struct exynos_context *)pkbdev->platform_context;
	if (!platform) return -ENODEV;
	if (sscanf(buf, "%d %d", &f, &v) != 2 || v < 600000 || v > 1200000)
		return -EINVAL;
	v = (v / 6250) * 6250;
	for (i = 0; i < platform->table_size; i++)
		if (platform->table[i].clock == f) { platform->table[i].voltage = v; hit = 1; }
	if (!hit) return -EINVAL;
	pr_info("gtactive2lte OC: gpu %d MHz -> %d uV\\n", f, v);
	return count;
}
DEVICE_ATTR(gta2_gpu_volt, S_IRUGO | S_IWUSR, show_gta2_gpu_volt, set_gta2_gpu_volt);

'''+a)
    b='	if (device_create_file(dev, &dev_attr_asv_table)) {\n'
    assert s.count(b)==1
    s=s.replace(b,'	if (device_create_file(dev, &dev_attr_gta2_gpu_volt))\n		GPU_LOG(DVFS_ERROR, DUMMY, 0u, 0u, "couldn\'t create sysfs file [gta2_gpu_volt]\\n");\n'+b)
    return s
edit('drivers/gpu/arm/t83x/r28p0/platform/exynos/gpu_custom_interface.c', ci)
print('ALL_PATCHED')
