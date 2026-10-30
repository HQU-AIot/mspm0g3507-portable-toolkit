[CmdletBinding()]
param([switch]$KeepWorkingDirectory)

. (Join-Path $PSScriptRoot 'Common.ps1')
$config = Get-ToolkitConfig
$sdk = Resolve-ToolkitPath $config.components.sdk
$example = Join-Path $sdk 'examples\nortos\LP_MSPM0G3507\driverlib\gpio_toggle_output'
if (-not (Test-Path -LiteralPath $example -PathType Container)) {
    throw "Smoke-test example is missing: $example"
}

$working = Join-Path ([IO.Path]::GetTempPath()) ("mspm0-toolkit-smoke-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $working | Out-Null
Copy-Item -LiteralPath $example -Destination $working -Recurse
$project = Join-Path $working 'gpio_toggle_output'

try {
    & (Join-Path $PSScriptRoot 'Build-Project.ps1') -ProjectPath $project
    if ($LASTEXITCODE -ne 0) { throw 'Build script returned a failure code.' }
    $output = Join-Path $project 'ticlang\gpio_toggle_output.out'
    if (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
        throw "Smoke-test output was not created: $output"
    }
    Write-Host "Smoke test passed: $output"
} finally {
    if ($KeepWorkingDirectory) {
        Write-Host "Smoke-test directory kept at $working"
    } elseif (Test-Path -LiteralPath $working) {
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
        $resolvedWorking = [IO.Path]::GetFullPath($working)
        if (-not $resolvedWorking.StartsWith($tempRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove a directory outside the temporary root: $resolvedWorking"
        }
        Remove-Item -LiteralPath $resolvedWorking -Recurse -Force
    }
}
