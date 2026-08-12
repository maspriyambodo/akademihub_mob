#requires -Version 5.1
<#
  Launcher AkademiHub Mobile.
  - Tampilkan daftar device yang terdeteksi.
  - Default: jalankan `flutter run` di device pertama (biasanya Android emulator).
  - Bila tidak ada device Android/iOS, tawarkan Windows desktop atau Web.
  Usage:
    .\run_app.ps1                # device pertama
    .\run_app.ps1 -List          # hanya tampilkan device
    .\run_app.ps1 -Web           # paksa jalan di Chrome
    .\run_app.ps1 -Windows       # paksa jalan di Windows desktop
    .\run_app.ps1 -ExtraArgs:'-d <id>'  # argumen tambahan ke flutter run
#>

[CmdletBinding()]
param(
  [switch]$List,
  [switch]$Web,
  [switch]$Windows,
  [string]$ExtraArgs
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

function Resolve-Flutter {
  $exe = Get-Command flutter -ErrorAction SilentlyContinue
  if ($null -ne $exe) { return $exe.Source }
  $candidates = @(
    'D:\dev\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat',
    "$env:LOCALAPPDATA\Pub\Cache\bin\flutter.bat"
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

$flutter = Resolve-Flutter
if (-not $flutter) {
  Write-Host 'Flutter tidak ditemukan di PATH atau lokasi default.' -ForegroundColor Red
  Write-Host 'Install Flutter atau tambahkan ke PATH lalu coba lagi.' -ForegroundColor Yellow
  Read-Host 'Tekan Enter untuk keluar'
  exit 1
}

Set-Location -LiteralPath $projectRoot

Write-Host ''
Write-Host '=== AkademiHub Mobile ===' -ForegroundColor Cyan
Write-Host "Flutter : $flutter"
Write-Host "Folder  : $projectRoot"
Write-Host ''

# Ambil daftar device
$devicesRaw = & $flutter devices 2>&1 | Out-String
Write-Host $devicesRaw

if ($List) {
  Read-Host 'Tekan Enter untuk keluar'
  exit 0
}

# Tentukan target
$targetArgs = @()
if ($Web) {
  $targetArgs = @('-d', 'chrome')
  Write-Host 'Menjalankan di Chrome (Web)...' -ForegroundColor Green
}
elseif ($Windows) {
  if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'windows'))) {
    Write-Host 'Folder windows/ belum ada. Menjalankan `flutter create . --platforms windows` terlebih dahulu...' -ForegroundColor Yellow
    & $flutter create . --platforms windows --no-overwrite | Out-Null
  }
  $targetArgs = @('-d', 'windows')
  Write-Host 'Menjalankan di Windows desktop...' -ForegroundColor Green
}
else {
  # Deteksi device Android/iOS otomatis
  $androidId = $null
  foreach ($line in ($devicesRaw -split "`r?`n")) {
    if ($line -match '^(?<id>\S+)\s+•\s+(?<name>.+?)\s+•\s+(?<platform>android|ios|emulator)\b') {
      $androidId = $matches.id
      break
    }
  }
  if ($androidId) {
    $targetArgs = @('-d', $androidId)
    Write-Host "Menjalankan di device: $androidId" -ForegroundColor Green
  }
  else {
    Write-Host 'Tidak ada device Android/iOS aktif.' -ForegroundColor Yellow
    Write-Host 'Pilih opsi:' -ForegroundColor Yellow
    Write-Host '  [1] Jalankan di Windows desktop (akan generate platform bila perlu)'
    Write-Host '  [2] Jalankan di Web (Chrome)'
    Write-Host '  [3] Batal'
    $pilihan = Read-Host 'Pilihan [1-3]'
    switch ($pilihan) {
      '1' {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'windows'))) {
          & $flutter create . --platforms windows --no-overwrite | Out-Null
        }
        $targetArgs = @('-d', 'windows')
        Write-Host 'Menjalankan di Windows desktop...' -ForegroundColor Green
      }
      '2' {
        $targetArgs = @('-d', 'chrome')
        Write-Host 'Menjalankan di Chrome (Web)...' -ForegroundColor Green
      }
      default {
        Write-Host 'Dibatalkan.' -ForegroundColor Yellow
        exit 0
      }
    }
  }
}

# Argumen tambahan dari -ExtraArgs
$extraArgs = @()
if ($ExtraArgs) { $extraArgs = ($ExtraArgs -split '\s+') | Where-Object { $_ -ne '' } }

Write-Host ''
Write-Host 'Menjalankan: flutter run ' ($targetArgs + $extraArgs -join ' ') -ForegroundColor DarkGray
Write-Host ''

& $flutter run @targetArgs @extraArgs

$exitCode = $LASTEXITCODE
Write-Host ''
Write-Host "flutter run selesai (exit code: $exitCode)" -ForegroundColor Cyan
Read-Host 'Tekan Enter untuk menutup jendela'
exit $exitCode
