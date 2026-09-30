[CmdletBinding()]
param(
    [ValidateSet('help','build','compile','test','check','install','clean','rebuild','doctor')]
    [string]$Task = 'help',
    [string]$Factorio = $env:FACTORIO_EXE,
    [string]$ModDirectory = $env:FACTORIO_MOD_DIR
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = $PSScriptRoot
$src = Join-Path $root 'src'
$work = Join-Path $root 'work'
$info = Get-Content -LiteralPath (Join-Path $src 'info.json') -Raw | ConvertFrom-Json
if ($info.name -notmatch '^[a-zA-Z0-9_-]+$' -or $info.version -notmatch '^\d+\.\d+\.\d+$') {
    throw 'Invalid mod name/version in src/info.json.'
}
$packageName = "$($info.name)_$($info.version)"
$dist = Join-Path $root 'dist'
$zip = Join-Path $dist "$packageName.zip"
if (-not $Factorio) {
    $Factorio = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\Factorio\bin\x64\factorio.exe'
}
if (-not $ModDirectory) { $ModDirectory = Join-Path $env:APPDATA 'Factorio\mods' }
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Write-Utf8([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $false))
}

function Build-Mod {
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    & (Join-Path $root 'tests/validate.ps1') -Source $src
    foreach ($file in @('info.json','control.lua','data.lua','settings.lua')) {
        if (-not (Test-Path -LiteralPath (Join-Path $src $file))) { throw "Missing source: $file" }
    }
    $temporary = "$zip.tmp"
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    $archive = [IO.Compression.ZipFile]::Open($temporary, 'Create')
    try {
        foreach ($file in Get-ChildItem -LiteralPath $src -Recurse -File | Sort-Object FullName) {
            $relative = $file.FullName.Substring($src.Length + 1).Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $file.FullName, "$packageName/$relative", 'Optimal') | Out-Null
        }
    } finally { $archive.Dispose() }
    Move-Item -LiteralPath $temporary -Destination $zip -Force
    Write-Host "Built: $zip"
}

function Get-TestConfig {
    if (-not (Test-Path -LiteralPath $Factorio -PathType Leaf)) {
        throw 'Factorio not found. Set FACTORIO_EXE or pass -Factorio with the executable path.'
    }
    $gameRoot = Split-Path (Split-Path (Split-Path $Factorio -Parent) -Parent) -Parent
    $data = Join-Path $gameRoot 'data'
    if (-not (Test-Path -LiteralPath (Join-Path $data 'base'))) { throw "Game data not found: $data" }
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $config = Join-Path $work 'config.ini'
    $readPath = $data.Replace('\','/')
    $writePath = $work.Replace('\','/')
    Write-Utf8 $config "[path]`nread-data=$readPath`nwrite-data=$writePath`n[general]`ncheck-updates=false`n"
    return $config
}

function Invoke-Headless([string]$Config, [string]$Mods, [string]$Label, [bool]$ExpectMarker) {
    $save = Join-Path $work "$Label.zip"
    $logPath = Join-Path $work "$Label.log"
    $errorPath = Join-Path $work "$Label.stderr.log"
    $arguments = @('--config', ('"' + $Config + '"'), '--mod-directory',
        ('"' + $Mods + '"'), '--create', ('"' + $save + '"'))
    $process = Start-Process -FilePath $Factorio -ArgumentList $arguments -Wait -PassThru `
        -WindowStyle Hidden -RedirectStandardOutput $logPath -RedirectStandardError $errorPath
    $exitCode = $process.ExitCode
    $text = [IO.File]::ReadAllText($logPath) + "`n" + [IO.File]::ReadAllText($errorPath)
    # Factorio can report Lua failure while returning exit code zero.
    if ($exitCode -ne 0 -or $text -match 'Error:|non-recoverable error|Error while running' -or
        $text -notmatch '(?m)^Done\.' -or -not (Test-Path -LiteralPath $save)) {
        throw "Factorio test failed ($Label). See $logPath`n$text"
    }
    if ($ExpectMarker -and $text -notmatch 'CURSOR ALIGNMENT TESTS PASSED') {
        throw "Smoke tests did not finish. See $logPath"
    }
    Write-Host "PASS: $Label"
}

function Test-Mod {
    Build-Mod
    $config = Get-TestConfig
    # Unique directories prevent old ZIPs/versions or failed test artifacts interfering.
    $run = Join-Path $work ([guid]::NewGuid().ToString('N'))
    $release = Join-Path $run 'release'
    $smoke = Join-Path $run 'smoke'
    New-Item -ItemType Directory -Force -Path $release,$smoke | Out-Null
    $mods = @{mods = @(
        @{name='base';enabled=$true}, @{name=$info.name;enabled=$true},
        @{name='space-age';enabled=$false}, @{name='quality';enabled=$false},
        @{name='elevated-rails';enabled=$false}, @{name='recycler';enabled=$false}
    )} | ConvertTo-Json -Depth 5
    Write-Utf8 (Join-Path $release 'mod-list.json') $mods
    Write-Utf8 (Join-Path $smoke 'mod-list.json') $mods
    Copy-Item -LiteralPath $zip -Destination $release
    Invoke-Headless $config $release 'release-load' $false
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $smoke)
    $control = Join-Path $smoke "$packageName/control.lua"
    $prefix = Get-Content -LiteralPath (Join-Path $root 'tests/prefix.lua') -Raw
    $suffix = Get-Content -LiteralPath (Join-Path $root 'tests/smoke.lua') -Raw
    Write-Utf8 $control ($prefix + "`n" + (Get-Content -LiteralPath $control -Raw) + "`n" + $suffix)
    Invoke-Headless $config $smoke 'behavior' $true
    Write-Host 'Tests passed. Visual appearance and real multiplayer are not covered.'
}

function Install-Mod {
    Test-Mod
    New-Item -ItemType Directory -Force -Path $ModDirectory | Out-Null
    $destination = Join-Path $ModDirectory "$packageName.zip"
    $listPath = Join-Path $ModDirectory 'mod-list.json'
    $backup = Join-Path $root ('backups/' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    if (Test-Path -LiteralPath $listPath) {
        Copy-Item -LiteralPath $listPath -Destination $backup
        $list = Get-Content -LiteralPath $listPath -Raw | ConvertFrom-Json
    } else { $list = [pscustomobject]@{mods=@()} }
    if (Test-Path -LiteralPath $destination) { Copy-Item -LiteralPath $destination -Destination $backup }
    $entry = @($list.mods | Where-Object { $_.name -eq $info.name })
    if ($entry.Count) { foreach ($item in $entry) { $item.enabled = $true } }
    else { $list.mods = @($list.mods) + [pscustomobject]@{name=$info.name;enabled=$true} }
    Copy-Item -LiteralPath $zip -Destination $destination -Force
    Write-Utf8 $listPath ($list | ConvertTo-Json -Depth 20)
    if ((Get-FileHash -LiteralPath $zip).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw 'Installed ZIP checksum does not match.'
    }
    Write-Host "Installed and enabled: $destination"
    Write-Host "Backup: $backup"
    Write-Host 'Restart Factorio to load the mod.'
}

function Clean-Mod {
    # Never delete saves, installed mods, source files, or installation backups.
    $resolvedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
    $resolvedWork = [IO.Path]::GetFullPath($work)
    if (-not $resolvedWork.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path $resolvedWork -Leaf) -ne 'work') { throw 'Unsafe cleanup path.' }
    if (Test-Path -LiteralPath $resolvedWork) { Remove-Item -LiteralPath $resolvedWork -Recurse -Force }
    foreach ($file in @($zip, "$zip.tmp")) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    Write-Host 'Removed generated work files and current package. Source and backups preserved.'
}

try {
    switch ($Task) {
        'build' { Build-Mod }
        'compile' { Build-Mod }
        'test' { Test-Mod }
        'check' { Test-Mod }
        'install' { Install-Mod }
        'clean' { Clean-Mod }
        'rebuild' { Clean-Mod; Test-Mod }
        'doctor' {
            Write-Host "Source: $src"
            Write-Host "Package: $zip"
            Write-Host "Mods: $ModDirectory"
            Get-TestConfig | Write-Host
            & $Factorio --version | Out-Host
            if ($LASTEXITCODE -ne 0) { throw 'Cannot run Factorio.' }
        }
        default {
            Write-Host 'Targets: build/compile, test/check, install, clean, rebuild, doctor, help'
            Write-Host 'Usage: make test  OR  .\build.ps1 test'
            Write-Host 'Lua is packaged, not compiled. install runs tests before installing.'
            Write-Host 'Overrides: FACTORIO_EXE, FACTORIO_MOD_DIR; or -Factorio / -ModDirectory.'
        }
    }
} catch { Write-Error $_ -ErrorAction Continue; exit 1 }
