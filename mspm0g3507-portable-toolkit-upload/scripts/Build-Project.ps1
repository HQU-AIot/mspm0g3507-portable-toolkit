[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$ProjectPath,

    [string]$MakeSubdirectory = 'ticlang',

    [string]$Target = 'all',

    [switch]$Clean
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$config = Get-ToolkitConfig
$makeSafeRoot = Get-MakeSafeToolkitRoot

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$makeDirectory = Join-Path $project $MakeSubdirectory
if (-not (Test-Path -LiteralPath (Join-Path $makeDirectory 'makefile') -PathType Leaf)) {
    if (Test-Path -LiteralPath (Join-Path $project 'makefile') -PathType Leaf) {
        $makeDirectory = $project
    } else {
        throw "No makefile found in $makeDirectory or $project"
    }
}

$gmake = Join-Path $makeSafeRoot ($config.components.make -replace '/', '\')
$sdk = Join-Path $makeSafeRoot ($config.components.sdk -replace '/', '\')
$compiler = Join-Path $makeSafeRoot ($config.components.compiler -replace '/', '\')
$sysconfig = Join-Path $makeSafeRoot (($config.components.sysconfig -replace '/', '\') + '\sysconfig_cli.bat')

foreach ($required in @($gmake, $sdk, $compiler, $sysconfig)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing toolkit component: $required" }
}

$variables = @(
    "MSPM0_SDK_INSTALL_DIR=$(ConvertTo-MakePath $sdk)",
    "TICLANG_ARMCOMPILER=$(ConvertTo-MakePath $compiler)",
    "SYSCONFIG_TOOL=$(ConvertTo-MakePath $sysconfig)"
)

if ($Clean) {
    $existingArtifacts = @(Get-ChildItem -LiteralPath $makeDirectory -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension -in @('.obj', '.out', '.map') -or $_.Name -like 'ti_msp_dl_config.*' -or $_.Name -like 'device.*'
    })
    if ($existingArtifacts.Count -gt 0) {
        & $gmake -C $makeDirectory @variables clean
        $cleanExitCode = $LASTEXITCODE
        if ($cleanExitCode -ne 0) {
            $remainingBuildOutputs = @(Get-ChildItem -LiteralPath $makeDirectory -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Extension -in @('.obj', '.out', '.map')
            })
            if ($remainingBuildOutputs.Count -gt 0) {
                throw "Clean failed with exit code $cleanExitCode and left build outputs behind."
            }
            Write-Warning "The SDK clean target returned $cleanExitCode after removing object/output/map files; continuing so SysConfig can regenerate its files."
        }
    } else {
        Write-Host 'Clean skipped: no generated build artifacts were found.'
    }
}

& $gmake -C $makeDirectory @variables $Target
if ($LASTEXITCODE -ne 0) { throw "Build target '$Target' failed with exit code $LASTEXITCODE" }
