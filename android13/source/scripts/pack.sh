#!/bin/bash
# manual packaging: target_files -> images -> OTA zip (no soong re-analysis)
cd ~/los20
export PATH=$PWD/out/host/linux-x86/bin:$PATH
P=out/target/product/gtactive2lte
T=$P/obj/PACKAGING/target_files_intermediates/lineage_gtactive2lte-target_files-eng.builder
ls -d $T || exit 1
rm -f $T/VENDOR/etc/recovery.img $T/VENDOR/bin/install-recovery.sh
sed -i '/^vendor\/etc\/recovery.img/d; /^vendor\/bin\/install-recovery.sh/d' $T/META/vendor_filesystem_config.txt
rm -f $T/VENDOR/lib/libsec-ril.so $T/VENDOR/lib/libsec-ril-dsds.so
sed -i '/^vendor\/lib\/libsec-ril/d' $T/META/vendor_filesystem_config.txt 2>/dev/null
du -sh $T/VENDOR $T/SYSTEM
rm -rf $T/IMAGES
add_img_to_target_files -a -v -p out/host/linux-x86 $T > ~/pack_addimg.log 2>&1; echo "addimg rc $?"
tail -n 5 ~/pack_addimg.log
ls -la $T/IMAGES
TF=$P/lineage_gtactive2lte-target_files.zip; rm -f $TF
A=$PWD/$TF; (cd $T && zip -qry $A .) ; ls -la $TF
D=$(date +%Y%m%d)
OUT=$P/lineage-20.0-$D-UNOFFICIAL-gtactive2lte.zip
ota_from_target_files -v -p out/host/linux-x86 -k build/make/target/product/security/testkey --block $TF $OUT > ~/pack_ota.log 2>&1; echo "ota rc $?"
tail -n 8 ~/pack_ota.log
ls -la $OUT && md5sum $OUT > $OUT.md5sum
echo PACK_DONE
