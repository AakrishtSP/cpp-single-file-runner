# Build and run one C/C++ file through CMake (Windows / PowerShell twin of run.sh).
#
#   .\run.ps1                     build src/main.cpp and run it
#   .\run.ps1 -File src\foo.c     build a different file
#   .\run.ps1 -Graphics           link graphics.h (libbgi, Windows/MinGW only)
#   .\run.ps1 -Release            Release build
#   .\run.ps1 -Clean              wipe the build directory first
#   .\run.ps1 -BuildOnly          build only, do not run
#   .\run.ps1 -- --flag arg       pass arguments to the program
param(
    [string]$File = "",
    [switch]$Release,
    [switch]$Graphics,
    [switch]$Clean,
    [switch]$BuildOnly,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ProgramArgs = @()
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$build = Join-Path $root "build"
$config = if ($Release) { "Release" } else { "Debug" }

if ($Clean -and (Test-Path $build)) {
    Remove-Item -Recurse -Force $build
}

$generator = $env:CMAKE_GENERATOR
if (-not $generator) {
    $generator = if (Get-Command ninja -ErrorAction SilentlyContinue) { "Ninja" } else { "" }
}

$configure = @("-S", $root, "-B", $build, "-DCMAKE_BUILD_TYPE=$config")
if ($generator) { $configure += @("-G", $generator) }
if ($File) { $configure += "-DFILE=$File" }
if ($Graphics) { $configure += "-DGRAPHICS=ON" }

& cmake @configure
& cmake --build $build --target app --config $config

if ($BuildOnly) { exit 0 }

$exe = Join-Path $build "app.exe"
if (-not (Test-Path $exe)) { $exe = Join-Path $build "app" }
& $exe @ProgramArgs
exit $LASTEXITCODE
