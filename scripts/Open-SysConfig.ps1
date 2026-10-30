[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SysCfgFile
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$config = Get-ToolkitConfig
$gui = Join-Path (Resolve-ToolkitPath $config.components.sysconfig) 'sysconfig_gui.bat'
$nw = Join-Path (Resolve-ToolkitPath $config.components.sysconfig) 'nw\nw.exe'
$product = Join-Path (Resolve-ToolkitPath $config.components.sdk) '.metadata\product.json'
if (-not (Test-Path -LiteralPath $gui -PathType Leaf) -or -not (Test-Path -LiteralPath $nw -PathType Leaf)) {
    throw 'SysConfig GUI is not installed in the local bundle. Re-run New-LocalBundle.ps1 with -IncludeSysConfigGui.'
}
& $gui --compiler ticlang --product $product (Resolve-Path -LiteralPath $SysCfgFile).Path
