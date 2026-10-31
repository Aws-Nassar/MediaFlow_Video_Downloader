param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

if (-not $env:JAVA_HOME) {
    $studioJbr = "C:\Program Files\Android\Android Studio\jbr"
    if (Test-Path -LiteralPath $studioJbr) { $env:JAVA_HOME = $studioJbr }
}
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA "Android\Sdk" }
if (-not (Test-Path -LiteralPath $env:ANDROID_HOME)) { throw "Set ANDROID_HOME to your Android SDK." }
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
Push-Location (Join-Path $PSScriptRoot "android")
try {
    if ($Clean) {
        & .\gradlew.bat clean --console=plain
        if ($LASTEXITCODE -ne 0) { throw "Gradle clean failed." }
    }
    & .\gradlew.bat :app:assembleDebug :app:lintDebug --console=plain
    if ($LASTEXITCODE -ne 0) { throw "Android build or lint failed." }
    Write-Host "APK: android/app/build/outputs/apk/debug/app-debug.apk" -ForegroundColor Green
} finally { Pop-Location }
