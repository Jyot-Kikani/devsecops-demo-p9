$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$kind = Join-Path $repo '.tools\kind.exe'
$kyvernoArchive = Join-Path $repo '.tools\cluster-images\cluster-images.tar'
if (!(Test-Path -LiteralPath $kyvernoArchive)) {
    throw 'Download and extract the p9-cluster-images workflow artifact into .tools\cluster-images first. See SETUP.md.'
}
function Confirm-Result {
    if ($LASTEXITCODE -ne 0) { throw "Image command failed with exit code $LASTEXITCODE." }
}
foreach ($image in @(
    'quay.io/argoproj/argocd:v3.5.5',
    'public.ecr.aws/docker/library/redis:8.2.3-alpine',
    'docker.io/dexidp/dex:v2.45.1'
)) {
    docker pull $image
    Confirm-Result
}
# Dex publishes the same release to Docker Hub and GHCR.
docker tag docker.io/dexidp/dex:v2.45.1 ghcr.io/dexidp/dex:v2.45.1
Confirm-Result
$argoArchive = Join-Path $repo '.tools\argocd-dependencies.tar'
docker image save --platform linux/amd64 -o $argoArchive quay.io/argoproj/argocd:v3.5.5 public.ecr.aws/docker/library/redis:8.2.3-alpine ghcr.io/dexidp/dex:v2.45.1
Confirm-Result
& $kind load image-archive $argoArchive --name devsecops-demo
Confirm-Result
& $kind load image-archive $kyvernoArchive --name devsecops-demo
Confirm-Result
Write-Output 'Official Argo CD and Kyverno images imported. Rerun scripts\Setup-Cluster.ps1.'
