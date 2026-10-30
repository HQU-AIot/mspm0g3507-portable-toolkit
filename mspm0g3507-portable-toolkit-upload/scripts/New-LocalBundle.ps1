[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SourceRoot,

    [ValidateSet('Lean', 'Full')]
    [string]$Profile = 'Lean',

    [switch]$IncludeSysConfigGui
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$source = (Resolve-Path -LiteralPath $SourceRoot).Path
$destination = Join-Path (Get-ToolkitRoot) 'vendor'
New-Item -ItemType Directory -Path $destination -Force | Out-Null

function Copy-Tree {
    param([Parameter(Mandatory)][string]$From, [Parameter(Mandatory)][string]$To)
    if (-not (Test-Path -LiteralPath $From -PathType Container)) {
        throw "Required source directory is missing: $From"
    }
    New-Item -ItemType Directory -Path $To -Force | Out-Null
    & robocopy $From $To /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with exit code $LASTEXITCODE while copying $From"
    }
}

function Copy-File {
    param([Parameter(Mandatory)][string]$From, [Parameter(Mandatory)][string]$ToDirectory)
    if (-not (Test-Path -LiteralPath $From -PathType Leaf)) {
        throw "Required source file is missing: $From"
    }
    New-Item -ItemType Directory -Path $ToDirectory -Force | Out-Null
    Copy-Item -LiteralPath $From -Destination $ToDirectory -Force
}

$components = @(
    'gmake',
    'openocd',
    'arm-none-eabi-gdb'
)
foreach ($name in $components) {
    Copy-Tree (Join-Path $source $name) (Join-Path $destination $name)
}

if ($Profile -eq 'Full') {
    foreach ($name in @('mspm0_sdk_2_10_00_04', 'ti-cgt-armllvm_4.0.4.LTS', 'sysconfig_1.27.0')) {
        Copy-Tree (Join-Path $source $name) (Join-Path $destination $name)
    }
    Write-Host "Full local bundle created at $destination"
    Write-Warning 'This bundle contains third-party software. Do not publish it without a component-by-component license review.'
    return
}

$sdkSource = Join-Path $source 'mspm0_sdk_2_10_00_04'
$sdkTarget = Join-Path $destination 'mspm0_sdk_2_10_00_04'
foreach ($relative in @(
    '.metadata',
    'source\ti\driverlib',
    'source\ti\devices',
    'source\ti\project_config',
    'source\ti\clockTree',
    'source\ti\tinyusb_meta',
    'source\third_party\CMSIS\Core\Include',
    'examples\nortos\LP_MSPM0G3507\driverlib\gpio_toggle_output'
)) {
    Copy-Tree (Join-Path $sdkSource $relative) (Join-Path $sdkTarget $relative)
}
foreach ($file in @('imports.mak', 'license_mspm0_sdk_2_10_00_04.txt', 'manifest_mspm0_sdk_2_10_00_04.html')) {
    Copy-File (Join-Path $sdkSource $file) $sdkTarget
}

$compilerSource = Join-Path $source 'ti-cgt-armllvm_4.0.4.LTS'
$compilerTarget = Join-Path $destination 'ti-cgt-armllvm_4.0.4.LTS'
foreach ($relative in @('bin', 'include', 'lib\armv6m-ti-none-eabi', 'lib\clang', 'opti-share')) {
    Copy-Tree (Join-Path $compilerSource $relative) (Join-Path $compilerTarget $relative)
}
New-Item -ItemType Directory -Path (Join-Path $compilerTarget 'lib') -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $compilerSource 'lib') -File | Copy-Item -Destination (Join-Path $compilerTarget 'lib') -Force
foreach ($file in @('README.html', 'TI_Arm_Clang_Compiler_4.0.3_manifest.html', 'TI_ARM_CLANG_RTS_4_0_0_LTS-a9812660-5d4e-4896-baea-458bbf54f61d.spdx')) {
    Copy-File (Join-Path $compilerSource $file) $compilerTarget
}

$sysconfigSource = Join-Path $source 'sysconfig_1.27.0'
$sysconfigTarget = Join-Path $destination 'sysconfig_1.27.0'
foreach ($relative in @('dist', 'nodejs')) {
    Copy-Tree (Join-Path $sysconfigSource $relative) (Join-Path $sysconfigTarget $relative)
}
foreach ($file in @('sysconfig_cli.bat', 'sysconfig_gui.bat')) {
    Copy-File (Join-Path $sysconfigSource $file) $sysconfigTarget
}
if ($IncludeSysConfigGui) {
    foreach ($relative in @('app', 'nw')) {
        Copy-Tree (Join-Path $sysconfigSource $relative) (Join-Path $sysconfigTarget $relative)
    }
}

Write-Host "Lean local bundle created at $destination"
if (-not $IncludeSysConfigGui) {
    Write-Host 'SysConfig GUI was not copied; CLI generation is available.'
}
Write-Warning 'The generated vendor directory is for local/internal use. Do not upload it as part of this repository.'
