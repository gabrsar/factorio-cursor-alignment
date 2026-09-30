param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference = 'Stop'
function Read-Keys($path) {
    $section = ''
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $path -Encoding UTF8) {
        if ($line -match '^\[([^\]]+)\]$') { $section = $Matches[1] }
        elseif ($line -match '^([^=;]+)=(.*)$') {
            $key = "$section.$($Matches[1])"
            if ($result.ContainsKey($key)) { throw "Duplicate translation: $key in $path" }
            if (-not $Matches[2].Trim()) { throw "Empty translation: $key in $path" }
            $result[$key] = $true
        }
    }
    return $result
}
$english = Read-Keys (Join-Path $Source 'locale/en/locale.cfg')
$locales = @(Get-ChildItem -LiteralPath (Join-Path $Source 'locale') -Directory)
foreach ($locale in $locales) {
    $keys = Read-Keys (Join-Path $locale.FullName 'locale.cfg')
    if ($keys.Count -ne $english.Count) { throw "Translation count mismatch: $($locale.Name)" }
    foreach ($key in $english.Keys) {
        if (-not $keys.ContainsKey($key)) { throw "Missing translation: $($locale.Name): $key" }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $Source 'thumbnail.png'))) { throw 'Missing thumbnail.' }
Write-Host "PASS: localization keys ($($locales.Count) languages) and thumbnail"
