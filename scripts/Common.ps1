Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ToolkitRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-ToolkitConfig {
    $configPath = Join-Path (Get-ToolkitRoot) 'toolkit.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Missing toolkit configuration: $configPath"
    }
    return (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json)
}

function Resolve-ToolkitPath {
    param([Parameter(Mandatory)][string]$RelativePath)
    $normalized = $RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar
    return [IO.Path]::GetFullPath((Join-Path (Get-ToolkitRoot) $normalized))
}

function ConvertTo-MakePath {
    param([Parameter(Mandatory)][string]$Path)
    return ([IO.Path]::GetFullPath($Path) -replace '\\', '/')
}

function Get-MakeSafeToolkitRoot {
    $root = [IO.Path]::GetFullPath((Get-ToolkitRoot))
    if ($root -notmatch '\s') {
        return $root
    }

    $rootItem = Get-Item -LiteralPath $root -Force
    $physicalRoot = $root
    if ($rootItem.LinkType -and $rootItem.Target) {
        $physicalRoot = [IO.Path]::GetFullPath([string]$rootItem.Target)
    }

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($physicalRoot.ToLowerInvariant())
        $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').Substring(0, 16)
    } finally {
        $sha.Dispose()
    }

    $aliasParent = Join-Path $env:LOCALAPPDATA 'mspm0-portable-toolkit'
    $alias = Join-Path $aliasParent ("root-$hash")
    New-Item -ItemType Directory -Path $aliasParent -Force | Out-Null
    if (Test-Path -LiteralPath $alias) {
        $aliasItem = Get-Item -LiteralPath $alias -Force
        if ($aliasItem.LinkType -ne 'Junction' -or [IO.Path]::GetFullPath([string]$aliasItem.Target) -ne $physicalRoot) {
            throw "Make-safe alias already exists but points elsewhere: $alias"
        }
    } else {
        New-Item -ItemType Junction -Path $alias -Target $physicalRoot | Out-Null
    }
    return $alias
}
