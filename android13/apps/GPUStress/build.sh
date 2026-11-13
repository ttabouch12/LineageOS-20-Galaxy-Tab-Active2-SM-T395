set -e
cd /root/upload/gpustress; T=/home/builder/los20
JDK=$T/prebuilts/jdk/jdk11/linux-x86/bin
AJ=$(ls $T/prebuilts/sdk/33/public/android.jar 2>/dev/null || find $T/prebuilts/sdk -path '*public/android.jar' | sort -V | tail -1); echo AJ=$AJ
B=$T/out/host/linux-x86; rm -rf build; mkdir -p build/classes build/dex
$JDK/javac -encoding UTF-8 -source 8 -target 8 -bootclasspath $AJ:$T/prebuilts/sdk/tools/core-lambda-stubs.jar -d build/classes $(find src -name '*.java') 2>&1 | grep -v 'warning' || true
ls build/classes/org/gta2/*/
$JDK/java -cp $B/framework/d8.jar com.android.tools.r8.D8 --release --min-api 29 --lib $AJ --output build/dex $(find build/classes -name '*.class')
$B/bin/aapt2 link -I $AJ --manifest AndroidManifest.xml --min-sdk-version 29 --target-sdk-version 33 -o build/unsigned.apk
(cd build/dex && zip -q ../unsigned.apk classes.dex)
$B/bin/zipalign -f 4 build/unsigned.apk build/aligned.apk
$JDK/java -jar $B/framework/apksigner.jar sign --key $T/build/make/target/product/security/testkey.pk8 --cert $T/build/make/target/product/security/testkey.x509.pem --out build/GPUStress.apk build/aligned.apk
$JDK/java -jar $B/framework/apksigner.jar verify -v build/GPUStress.apk | head -4
cp build/GPUStress.apk /tmp/out/
