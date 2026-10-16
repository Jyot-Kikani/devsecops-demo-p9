$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$kind = Join-Path $repo '.tools\kind.exe'
$helm = Join-Path $repo '.tools\helm-portable\windows-amd64\helm.exe'
$kubeconfig = Join-Path $repo '.tools\kubeconfig'
function Confirm-NativeResult {
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE." }
}
if (!(Test-Path $kind) -or !(Test-Path $helm)) {
    throw 'Portable kind and Helm are required in .tools. See SETUP.md.'
}
& $kind get clusters | Select-String '^devsecops-demo$' | Out-Null
if (!$?) { throw 'Cannot inspect kind clusters. Start Docker Desktop.' }
$clusters = & $kind get clusters
Confirm-NativeResult
if ($clusters -notcontains 'devsecops-demo') {
    & $kind create cluster --name devsecops-demo --image kindest/node:v1.36.1 --kubeconfig $kubeconfig --wait 120s
    Confirm-NativeResult
} else {
    & $kind export kubeconfig --name devsecops-demo --kubeconfig $kubeconfig
    Confirm-NativeResult
}
foreach ($namespace in @('argocd', 'p9-demo')) {
    kubectl --kubeconfig $kubeconfig create namespace $namespace --dry-run=client -o yaml | kubectl --kubeconfig $kubeconfig apply -f -
    Confirm-NativeResult
}
kubectl --kubeconfig $kubeconfig apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.5/manifests/install.yaml
Confirm-NativeResult
& $helm repo add kyverno https://kyverno.github.io/kyverno/ --repository-config (Join-Path $repo '.tools\helm-repositories.yaml') --repository-cache (Join-Path $repo '.tools\helm-cache')
Confirm-NativeResult
& $helm upgrade --install kyverno kyverno/kyverno --version 3.9.1 -n kyverno --create-namespace --kubeconfig $kubeconfig --repository-config (Join-Path $repo '.tools\helm-repositories.yaml') --repository-cache (Join-Path $repo '.tools\helm-cache') --wait --timeout 10m
Confirm-NativeResult
kubectl --kubeconfig $kubeconfig apply -f (Join-Path $repo 'kyverno\disallow-root.yaml')
Confirm-NativeResult
Write-Output 'Cluster components installed. Build and load the fixed image before applying argocd/application.yaml. See README.md.'
