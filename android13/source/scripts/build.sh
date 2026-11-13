#!/bin/bash
# full build, logs to ~/build.log
T=~/los20; cd $T
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=~/.ccache LC_ALL=C
ccache -M 50G >/dev/null
source build/envsetup.sh
lunch lineage_gtactive2lte-userdebug || exit 3

m bacon -j${JOBS:-8}
echo "BUILD_EXIT=$?"
ls -la out/target/product/gtactive2lte/*.zip out/target/product/gtactive2lte/*.img 2>/dev/null
