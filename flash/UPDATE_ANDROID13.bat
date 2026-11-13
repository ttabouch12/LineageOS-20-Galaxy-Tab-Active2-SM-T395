@echo off
setlocal enabledelayedexpansion
rem Galaxy Tab Active2 (SM-T395): install the UPDATE2 zip over the current LineageOS 20. KEEPS your apps and data.
cd /d "%~dp0"
set ADB=%USERPROFILE%\Downloads\Legion-ZUXOS-Lite\platform-tools\adb.exe
if not exist "%ADB%" set ADB=adb
set LOG=%~dp0log_update_android13.txt
set ZIP=lineage-20.0-20261113-gtactive2lte-OC-FINAL.zip
echo ==== %date% %time% ==== > "%LOG%"
if not exist "%ZIP%" ( echo %ZIP% not found next to this script. & pause & exit /b 1 )
echo Update: %ZIP%   (your apps and data are kept)
echo.
echo Tablet on, unlocked, USB debugging allowed, plugged in. Press any key to start.
pause >nul
"%ADB%" reboot recovery >> "%LOG%" 2>&1
echo Rebooting into TWRP...
"%ADB%" wait-for-recovery >> "%LOG%" 2>&1
timeout /t 5 /nobreak >nul
"%ADB%" shell twrp wipe cache >> "%LOG%" 2>&1
"%ADB%" shell twrp wipe dalvik >> "%LOG%" 2>&1
echo Installing the update (sideload, about 5 minutes)...
"%ADB%" shell twrp sideload >> "%LOG%" 2>&1
timeout /t 5 /nobreak >nul
"%ADB%" sideload "%ZIP%" >> "%LOG%" 2>&1
echo sideload exit !errorlevel! >> "%LOG%"
timeout /t 10 /nobreak >nul
if exist Magisk-v31.1.zip (
  echo Re-installing Magisk root...
  "%ADB%" wait-for-recovery >> "%LOG%" 2>&1
  "%ADB%" shell twrp sideload >> "%LOG%" 2>&1
  timeout /t 5 /nobreak >nul
  "%ADB%" sideload Magisk-v31.1.zip >> "%LOG%" 2>&1
  timeout /t 10 /nobreak >nul
)
"%ADB%" wait-for-recovery >> "%LOG%" 2>&1
"%ADB%" reboot >> "%LOG%" 2>&1
echo UPDATE_DONE >> "%LOG%"
echo.
echo Done. The first boot after the update takes a few minutes (apps get re-optimised).
pause
