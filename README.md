# Practical 9: DevSecOps demo

Based on [DrVCprog/devsecops-demo](https://github.com/DrVCprog/devsecops-demo), with Windows commands and no Slack integration.

The learning sequence is: detect insecure code, fix it, synchronize Kubernetes configuration from Git, and reject deployments which violate policy. Run this deliberately vulnerable app only on the local lab machine.

## What runs

- GitHub Actions: independent Gitleaks, Semgrep, Trivy dependency, Hadolint, and image-build/Trivy jobs.
- Argo CD: synchronizes only `gitops/` from `main`.
- Kyverno: requires `runAsNonRoot: true` in the `p9-demo` namespace.
- The cluster runs the fixed Flask app, built locally and loaded into kind. This demo does not publish container images to a registry.

The first tool downloads can take time. Start Docker Desktop before running local commands.

## 1. Show a vulnerable pipeline

Run from this repository in PowerShell:

```powershell
.\scripts\Set-DemoState.ps1 Vulnerable
git add app.py Dockerfile requirements.txt
git commit -m "Demo: vulnerable app"
git push
```

Open the [Actions tab](https://github.com/Jyot-Kikani/devsecops-demo-p9/actions). Semgrep should find SQL injection, Trivy should find vulnerable dependencies, and Hadolint should reject explicit `USER root`. Gitleaks passes because no demo token exists. Each check runs independently.

Original upstream files remain available in Git history. Repeatable vulnerable and corrected versions are in `examples/`. Hadolint's DL3002 checks explicit `USER root`; a missing USER instruction alone does not trigger it.

## 2. Show secret detection

```powershell
.\scripts\Set-DemoState.ps1 Secret
git add app.py Dockerfile requirements.txt config.py
git commit -m "Demo: fake secret detection"
git push
```

This starts from the fixed app and writes a randomly generated **fake lab token**. The custom Gitleaks rule detects it and redacts its value. No real AWS account or credentials are needed.

For this repeatable exercise, Gitleaks scans current files, not all Git history. Removing a real leaked credential would also require revocation and handling its history; deleting a file is sufficient only for this fake-token exercise.

## 3. Fix and rerun

```powershell
.\scripts\Set-DemoState.ps1 Fixed
git add -A
git commit -m "Fix SQL injection, dependencies and root container"
git push
```

The fixed app uses a parameterized SQL query, updated dependencies, and numeric non-root UID 10001. The expected result is all jobs passing. Vulnerability databases change, so inspect the actual findings if an updated scan reports a new issue.

To run the same tools locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Check-Security.ps1
```

Use `-Scanner Gitleaks`, `Semgrep`, `Dependencies`, `Hadolint`, or `Image` for an individual check.

## 4. Prepare Kubernetes and the image

See [SETUP.md](SETUP.md) for portable tools. Then:

```powershell
.\scripts\Setup-Cluster.ps1
.\scripts\Set-DemoState.ps1 Fixed
docker build -t p9-demo:fixed .
.\.tools\kind.exe load docker-image p9-demo:fixed --name devsecops-demo
kubectl --kubeconfig .tools\kubeconfig apply -f argocd\application.yaml
kubectl --kubeconfig .tools\kubeconfig get pods -n argocd
kubectl --kubeconfig .tools\kubeconfig get applications -n argocd
```

Argo CD can take a few minutes to become ready. It should show `p9-demo` as Synced and Healthy once the app starts.

## 5. Show GitOps synchronization

In `gitops/deployment.yaml`, change `replicas: 2` to `replicas: 3`, commit, and push. Observe Argo CD applying the change, then check:

```powershell
kubectl --kubeconfig .tools\kubeconfig get deployment demo-app -n p9-demo
```

To request an immediate refresh instead of waiting for polling:

```powershell
kubectl --kubeconfig .tools\kubeconfig annotate application p9-demo -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

## 6. Show Kyverno rejecting and accepting deployments

```powershell
kubectl --kubeconfig .tools\kubeconfig apply -f k8s\deployment.yaml
# Expected: denied by disallow-root-p9.
kubectl --kubeconfig .tools\kubeconfig apply -f k8s\deployment.fixed.yaml
# Expected: accepted.
```

Argo CD self-healing will reconcile any later differences back to `gitops/`. The policy is limited to the demo namespace and also validates generated Deployment Pod templates.

## 7. Open the local demo

In separate PowerShell terminals:

```powershell
kubectl --kubeconfig .tools\kubeconfig port-forward -n argocd svc/argocd-server 8089:443 --address 127.0.0.1
kubectl --kubeconfig .tools\kubeconfig port-forward -n p9-demo svc/demo-app 5009:5000 --address 127.0.0.1
```

- Argo CD: https://localhost:8089 (local self-signed certificate), username `admin`.
- Flask app: http://127.0.0.1:5009/user?name=admin

Retrieve the Argo CD password locally; do not include it in screenshots:

```powershell
$encoded = kubectl --kubeconfig .tools\kubeconfig get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
```

Capture: vulnerable pipeline findings, fake-secret detection, fixed pipeline success, Argo CD Synced/Healthy, changed replica count, policy rejection, and accepted deployment. Local validation outputs belong in the ignored `evidence/` directory.

## Changes from the supplied demo

Slack was removed. Missing fixed manifests were supplied, the identical vulnerable/fixed dependency lists were corrected, SQL injection is actually fixed, the fixed container can write its SQLite database, and Argo CD reads a separate directory so it does not apply duplicate broken/fixed Deployments. Image scanning fails on fixable HIGH/CRITICAL vulnerabilities rather than silently passing.
