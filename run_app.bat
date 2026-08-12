@echo off
REM Launcher AkademiHub Mobile (wrapper untuk run_app.ps1)
REM Penggunaan:
REM   run_app.bat            - device pertama
REM   run_app.bat -list      - tampilkan daftar device
REM   run_app.bat -web       - jalankan di Chrome
REM   run_app.bat -windows   - jalankan di Windows desktop

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_app.ps1" %*
