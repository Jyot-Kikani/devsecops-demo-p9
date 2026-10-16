param(
    [Parameter(Mandatory)]
    [ValidateSet('Vulnerable', 'Fixed', 'Secret')]
    [string]$State
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = if ($State -eq 'Vulnerable') { 'vulnerable' } else { 'fixed' }
foreach ($name in @('app.py', 'Dockerfile', 'requirements.txt')) {
    Copy-Item -LiteralPath (Join-Path $repo "examples\$source\$name") -Destination (Join-Path $repo $name) -Force
}
$configPath = Join-Path $repo 'config.py'
if ($State -eq 'Secret') {
    $fakeToken = 'p9demo_' + [guid]::NewGuid().ToString('N')
    Set-Content -LiteralPath $configPath -Value ('P9_DEMO_TOKEN = "' + $fakeToken + '"') -Encoding ascii
} elseif (Test-Path -LiteralPath $configPath) {
    Remove-Item -LiteralPath $configPath
}
Write-Output "P9 state: $State. Files changed locally; commit and push to run GitHub Actions."
