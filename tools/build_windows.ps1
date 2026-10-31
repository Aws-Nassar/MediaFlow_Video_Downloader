param([switch]$InstallDependencies, [switch]$DownloadRuntime)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$python = Join-Path $project '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) { throw 'Create the project .venv first.' }
Push-Location $project
try {
    if ($InstallDependencies) {
        & $python -m pip install -r requirements-dev.txt
        if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
    }
    if ($DownloadRuntime) {
        $archive = Join-Path $project 'build\deno-windows.zip'
        New-Item -ItemType Directory -Force -Path (Split-Path $archive -Parent) | Out-Null
        Invoke-WebRequest 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' -OutFile $archive
        Expand-Archive -LiteralPath $archive -DestinationPath $PSScriptRoot -Force
    }
    $runtime = Join-Path $PSScriptRoot 'deno.exe'
    if (-not (Test-Path -LiteralPath $runtime) -and -not (Get-Command deno -ErrorAction SilentlyContinue)) {
        throw 'Deno is required for the portable YouTube build. Run with -DownloadRuntime, or put deno.exe in tools/.'
    }
    foreach ($binary in @('ffmpeg.exe', 'ffprobe.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $binary)) -and -not (Get-Command $binary -ErrorAction SilentlyContinue)) {
            throw "$binary is required. Put it in tools/ or add it to PATH."
        }
    }
    & $python -m PyInstaller --noconfirm MediaFlow.spec
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
    Write-Host 'EXE: dist\MediaFlow.exe' -ForegroundColor Green
} finally { Pop-Location }
