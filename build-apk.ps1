# Build a signed release APK of Perlite Flow.
#
# This machine's JDK 17+/21 breaks Gradle daemon NIO pipes under
# Windows AF_UNIX (a third-party socket filter rejects loopback
# connects into $env:TEMP). We work around it by:
#   1. Pointing TEMP/TMP at a project-local dir while Gradle runs.
#   2. Using Temurin JDK 21 (Pipe.open() falls back to a normal
#      TCP loopback when AF_UNIX is unavailable).
#
# The signing key lives in android/app/release.keystore and the
# password in android/key.properties (both gitignored).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tmp  = Join-Path $root 'android\.unix-tmp'
New-Item -ItemType Directory -Force $tmp | Out-Null

# Prefer Temurin 21; fall back to Android Studio's JBR or JAVA_HOME.
$jdk = @(
    'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot',
    'C:\Program Files\Android\Android Studio\jbr',
    $env:JAVA_HOME
) | Where-Object { $_ -and (Test-Path "$_\bin\java.exe") } | Select-Object -First 1

if (-not $jdk) { throw 'No JDK found. Install Eclipse Temurin 21 or Android Studio.' }

$env:JAVA_HOME = $jdk
$env:TEMP     = $tmp
$env:TMP      = $tmp
$env:GRADLE_OPTS = '-Djdk.io.pipesUseUnixDomainSockets=false'

Write-Host "JAVA_HOME = $jdk" -ForegroundColor Cyan
Write-Host "TEMP      = $tmp" -ForegroundColor Cyan

Set-Location $root

# Minutes since 2024-01-01 UTC. CI uses the same formula, so versionCode
# keeps increasing without overflowing Android's integer limit.
$epoch = [DateTimeOffset]::Parse('2024-01-01T00:00:00Z')
$buildNo = [int][math]::Floor(([DateTimeOffset]::UtcNow - $epoch).TotalMinutes)
$pubspec = Get-Content "$root\pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)') {
    Write-Host "versionName = $($Matches[1]), versionCode = $buildNo" -ForegroundColor Cyan
}

$flutter = 'C:\code\sdk\flutter\bin\flutter.bat'
$dart = 'C:\code\sdk\flutter\bin\dart.bat'
& $flutter config --jdk-dir=$jdk | Out-Null
& $flutter build apk --release --split-per-abi --build-number $buildNo @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $dart run tool/package_apks.dart $buildNo dist
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'APKs:' -ForegroundColor Green
Get-ChildItem "$root\dist\*.apk" |
    Select-Object Name, @{N='MB';E={[math]::Round($_.Length/1MB,1)}}, LastWriteTime
