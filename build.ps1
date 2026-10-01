[CmdletBinding()]
param(
  [string]$Task = 'help',
  [string]$Factorio = $env:FACTORIO_EXE,
  [string]$ModDirectory = $env:FACTORIO_MOD_DIR,
  [string]$DataDirectory = $env:FACTORIO_DATA_DIR
)
$ErrorActionPreference = 'Stop'
$arguments = @((Join-Path $PSScriptRoot 'tools/build.py'), $Task)
if ($Factorio) { $arguments += @('--factorio', $Factorio) }
if ($ModDirectory) { $arguments += @('--mod-dir', $ModDirectory) }
if ($DataDirectory) { $arguments += @('--data-dir', $DataDirectory) }
if (Get-Command py -ErrorAction SilentlyContinue) { & py -3 @arguments }
elseif (Get-Command python -ErrorAction SilentlyContinue) { & python @arguments }
else { throw 'Python 3.9+ is required. Install Python or run tools/build.py with your Python executable.' }
exit $LASTEXITCODE
