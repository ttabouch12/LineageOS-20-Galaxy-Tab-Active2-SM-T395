#!/bin/bash
cd ~/los20; mkdir -p ~/tmpota; rm -rf ~/tmpota/*; export TMPDIR=$HOME/tmpota
export PATH=$PWD/out/host/linux-x86/bin:$PWD/prebuilts/jdk/jdk11/linux-x86/bin:$PATH; which java
P=out/target/product/gtactive2lte
TF=$P/lineage_gtactive2lte-target_files.zip
R=/tmp/rt; rm -rf $R; cp -r build/make/tools/releasetools $R
sed -i 's/^  assert HasRecoveryPatch(input_zip, info_dict=OPTIONS.info_dict)/  pass  # gtactive2lte: TWRP stays in RECOVERY, no recovery-from-boot/' $R/non_ab_ota.py
grep -n "gtactive2lte: TWRP" $R/non_ab_ota.py
cat > $R/imp.py <<'IMP'
# minimal "imp" shim for Python 3.12+
import importlib.util, importlib.machinery, os
PY_SOURCE = 1
def load_source(name, path):
    loader = importlib.machinery.SourceFileLoader(name, path)
    spec = importlib.util.spec_from_loader(name, loader)
    m = importlib.util.module_from_spec(spec); loader.exec_module(m); return m
def find_module(name, path=None):
    for d in (path or []):
        f = os.path.join(d, name + ".py")
        if os.path.exists(f): return (open(f), f, (".py", "r", PY_SOURCE))
        f = os.path.join(d, name, "__init__.py")
        if os.path.exists(f): return (None, os.path.join(d, name), ("", "", 5))
    raise ImportError(name)
def load_module(name, file, pathname, desc):
    if file: file.close()
    if os.path.isdir(pathname): pathname = os.path.join(pathname, "__init__.py")
    return load_source(name, pathname)
IMP
D=$(date +%Y%m%d); OUT=$P/lineage-20.0-$D-UNOFFICIAL-gtactive2lte.zip
PYTHONPATH=$R:$PWD/development/python-packages python3 $R/ota_from_target_files.py -v -p out/host/linux-x86 -k build/make/target/product/security/testkey --block $TF $OUT > ~/pack_ota.log 2>&1; echo "ota rc $?"
tail -n 15 ~/pack_ota.log | cut -c1-250
ls -la $OUT && md5sum $OUT | tee $OUT.md5sum
echo OTA_DONE
