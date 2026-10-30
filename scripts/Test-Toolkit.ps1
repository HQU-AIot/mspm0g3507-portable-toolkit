[CmdletBinding()]
param([switch]$SmokeTest)

. (Join-Path $PSScriptRoot 'Common.ps1')
$config = Get-ToolkitConfig

$paths = [ordered]@{
    'MSPM0 SDK metadata' = Join-Path (Resolve-ToolkitPath $config.components.sdk) '.metadata\product.json'
    'TI Arm Clang'       = Join-Path (Resolve-ToolkitPath $config.components.compiler) 'bin\tiarmclang.exe'
    'SysConfig CLI'      = Join-Path (Resolve-ToolkitPath $config.components.sysconfig) 'sysconfig_cli.bat'
    'GNU Make'           = Resolve-ToolkitPath $config.components.make
    'OpenOCD'            = Join-Path (Resolve-ToolkitPath $config.components.openocd) 'bin\openocd.exe'
    'MSPM0 OpenOCD cfg'  = Join-Path (Resolve-ToolkitPath $config.components.openocd) 'share\openocd\scripts\target\ti_mspm0.cfg'
    'Arm GDB'            = Resolve-ToolkitPath $config.components.gdb
}

$failed = $false
$presenceRows = @(foreach ($entry in $paths.GetEnumerator()) {
    $exists = Test-Path -LiteralPath $entry.Value -PathType Leaf
    [pscustomobject]@{ Component = $entry.Key; Present = $exists; Path = $entry.Value }
    if (-not $exists) { $failed = $true }
})
$presenceRows | Format-Table -AutoSize | Out-Host

if ($failed) {
    throw 'Toolkit is incomplete. Run New-LocalBundle.ps1 or install the missing components.'
}

$lockPath = Join-Path (Get-ToolkitRoot) 'components.lock.json'
$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
Write-Host "`nChecksum checks:"
$checksumRows = @(foreach ($property in $lock.files.PSObject.Properties) {
    $filePath = Resolve-ToolkitPath $property.Name
    $actual = (Get-FileHash -LiteralPath $filePath -Algorithm $lock.algorithm).Hash
    $matches = $actual -eq [string]$property.Value
    [pscustomobject]@{ File = $property.Name; Match = $matches }
    if (-not $matches) { throw "Checksum mismatch: $filePath" }
})
$checksumRows | Format-Table -AutoSize | Out-Host

Write-Host "`nVersion checks:"
& $paths['TI Arm Clang'] --version | Select-Object -First 1
& $paths['GNU Make'] --version | Select-Object -First 1
$openOcdCommand = '"' + $paths['OpenOCD'] + '" --version 2>&1'
$openOcdVersion = & $env:ComSpec /d /s /c $openOcdCommand
$openOcdVersion | Select-Object -First 1
& $paths['Arm GDB'] --version | Select-Object -First 1
& $paths['SysConfig CLI'] --version
if ($LASTEXITCODE -ne 0) { throw 'SysConfig version check failed.' }

if ($SmokeTest) {
    & (Join-Path $PSScriptRoot 'Invoke-SmokeTest.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Smoke test failed.' }
}
