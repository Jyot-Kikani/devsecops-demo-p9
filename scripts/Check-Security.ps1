param([ValidateSet('All', 'Gitleaks', 'Semgrep', 'Dependencies', 'Hadolint', 'Image')][string]$Scanner = 'All')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$results = @()
Push-Location $repo
try {
    foreach ($check in @('Gitleaks', 'Semgrep', 'Dependencies', 'Hadolint', 'Image')) {
        if ($Scanner -ne 'All' -and $Scanner -ne $check) { continue }
        Write-Host ''
        Write-Host "=== $check ==="
        switch ($check) {
            Gitleaks {
                docker run --rm -v ($repo + ':/repo') ghcr.io/gitleaks/gitleaks:v8.30.1 dir /repo --config /repo/.gitleaks.toml --redact --exit-code 1
            }
            Semgrep {
                docker run --rm -v ($repo + ':/src') -w /src semgrep/semgrep:1.181.0 semgrep scan --config .semgrep.yml --error --metrics=off app.py
            }
            Dependencies {
                docker run --rm -v ($repo + ':/repo') -v p9-trivy-cache:/root/.cache/trivy aquasec/trivy:0.76.0 fs --scanners vuln --severity MEDIUM,HIGH,CRITICAL --exit-code 1 /repo/requirements.txt
            }
            Hadolint {
                Get-Content -Raw Dockerfile | docker run --rm -i hadolint/hadolint:v2.14.0
            }
            Image {
                docker build -t p9-demo:scan .
                if ($LASTEXITCODE -eq 0) {
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v p9-trivy-cache:/root/.cache/trivy aquasec/trivy:0.76.0 image --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 p9-demo:scan
                }
            }
        }
        $results += [pscustomobject]@{ Scanner = $check; ExitCode = $LASTEXITCODE }
    }
} finally { Pop-Location }
$results | Format-Table -AutoSize
if ($results.ExitCode | Where-Object { $_ -ne 0 }) { exit 1 }
