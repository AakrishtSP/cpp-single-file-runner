# Build and run one C/C++ file through CMake (Windows / PowerShell twin of run.sh).
#
#   .\run.ps1                     build src/main.cpp and run it
#   .\run.ps1 -File src\foo.c     build a different file
#   .\run.ps1 -Std 23             C++ standard 17, 20 or 23
#   .\run.ps1 -ImportStd          use `import std;` (C++23 std module)
#   .\run.ps1 -Release            Release build
#   .\run.ps1 -Clean              wipe the build directory first
#   .\run.ps1 -BuildOnly          build only, do not run
#   .\run.ps1 -- --flag arg       pass arguments to the program
param(
    [string]$File = "",
    [string]$Std = "",
    [switch]$ImportStd,
    [switch]$Release,
    [switch]$Clean,
    [switch]$BuildOnly,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ProgramArgs = @()
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
# `import std` is gated before compiler detection, so it gets its own build
# directory: flipping the flag inside one cache makes CMake refuse to generate.
$build = Join-Path $root $(if ($ImportStd) { "build-import-std" } else { "build" })
$config = if ($Release) { "Release" } else { "Debug" }

if ($Clean) {
    foreach ($dir in @("build", "build-import-std")) {
        $p = Join-Path $root $dir
        if (Test-Path $p) { Remove-Item -Recurse -Force $p }
    }
}

$generator = $env:CMAKE_GENERATOR
if (-not $generator) {
    $generator = if (Get-Command ninja -ErrorAction SilentlyContinue) { "Ninja" } else { "" }
}

$configure = @("-S", $root, "-B", $build, "-DCMAKE_BUILD_TYPE=$config")
if ($generator) { $configure += @("-G", $generator) }
if ($File) { $configure += "-DFILE=$File" }
if ($Std) { $configure += "-DCPP_STD=$Std" }
$configure += "-DIMPORT_STD=$(if ($ImportStd) { 'ON' } else { 'OFF' })"

& cmake @configure
& cmake --build $build --target app --config $config

if ($BuildOnly) { exit 0 }

$exe = Join-Path $build "app.exe"
if (-not (Test-Path $exe)) { $exe = Join-Path $build "app" }
& $exe @ProgramArgs
exit $LASTEXITCODE
