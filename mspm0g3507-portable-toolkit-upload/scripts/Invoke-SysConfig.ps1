[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SysCfgFile,

    [Parameter(Mandatory)]
    [string]$OutputDirectory,

    [switch]$TreatWarningsAsErrors
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$config = Get-ToolkitConfig

$sysconfig = Join-Path (Resolve-ToolkitPath $config.components.sysconfig) 'sysconfig_cli.bat'
$product = Join-Path (Resolve-ToolkitPath $config.components.sdk) '.metadata\product.json'
if (-not (Test-Path -LiteralPath $sysconfig -PathType Leaf)) { throw "Missing SysConfig CLI: $sysconfig" }
if (-not (Test-Path -LiteralPath $product -PathType Leaf)) { throw "Missing SDK product metadata: $product" }

$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$arguments = @('--compiler', 'ticlang', '--product', $product, '--script', (Resolve-Path -LiteralPath $SysCfgFile).Path, '--output', $output)
if ($TreatWarningsAsErrors) { $arguments += '--treatWarningsAsErrors' }

& $sysconfig @arguments
if ($LASTEXITCODE -ne 0) { throw "SysConfig generation failed with exit code $LASTEXITCODE" }
