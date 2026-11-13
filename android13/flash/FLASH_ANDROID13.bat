@echo off
setlocal enabledelayedexpansion
rem Galaxy Tab Active2 LTE (SM-T395) - CLEAN install of LineageOS 20 OC build from TWRP.
rem ERASES EVERYTHING on the tablet (apps, files). /data is re-created as F2FS on first boot.
rem Put next to: lineage-20.0-*-gtactive2lte-OC-FINAL.zip, Magisk-v31.1.zip (optional), fmt_data.sh, adb.exe (platform-tools)
cd /d "%~dp0"
set ADB=adb
if exist "%~dp0platform-tools\adb.exe" set ADB=%~dp0platform-tools\adb.exe
set LOG=%~dp0log_flash.txt
set ZIP=
for %%Z in (lineage-20.0-*-gtactive2lte*.zip) do set ZIP=%%Z
if "%ZIP%"=="" ( echo ROM zip not found next to this script. & pause & exit /b 1 )
echo ROM: %ZIP%
echo.
echo This ERASES everything on the tablet. Close this window to cancel.
echo 1. Boot TWRP: power off, hold VOLUME UP + HOME + POWER.
echo 2. Plug the tablet into this PC.
pause
echo ==== %date% %time% ==== > "%LOG%"
"%ADB%" wait-for-recovery >> "%LOG%" 2>&1
"%ADB%" shell twrp wipe system >> "%LOG%" 2>&1
"%ADB%" shell twrp wipe vendor >> "%LOG%" 2>&1
"%ADB%" shell twrp wipe cache >> "%LOG%" 2>&1
"%ADB%" shell twrp wipe dalvik >> "%LOG%" 2>&1
echo Erasing data (Android formats it as F2FS on first boot)...
"%ADB%" push fmt_data.sh /tmp/fmt_data.sh >> "%LOG%" 2>&1
"%ADB%" shell sh /tmp/fmt_data.sh >> "%LOG%" 2>&1
echo Installing the ROM (about 5 minutes)...
"%ADB%" shell twrp sideload >> "%LOG%" 2>&1
ping -n 6 127.0.0.1 >nul
"%ADB%" sideload "%ZIP%" >> "%LOG%" 2>&1
ping -n 12 127.0.0.1 >nul
if exist Magisk-v31.1.zip (
  echo Installing Magisk root...
  "%ADB%" wait-for-recovery >> "%LOG%" 2>&1
  "%ADB%" shell twrp sideload >> "%LOG%" 2>&1
  ping -n 6 127.0.0.1 >nul
  "%ADB%" sideload Magisk-v31.1.zip >> "%LOG%" 2>&1
  ping -n 12 127.0.0.1 >nul
)
"%ADB%" wait-for-recovery >> "%LOG%" 2>&1
"%ADB%" reboot >> "%LOG%" 2>&1
echo.
echo Done. The first boot takes 5-10 minutes. Log: log_flash.txt
pause
