# Windows setup for P9

Docker Desktop and kubectl are already installed on this machine. The P9 kind cluster uses its own `.tools/kubeconfig`; every lab command selects it explicitly.

Portable tools are stored locally in ignored `.tools/` and do not require a global installation. If restoring on another computer, run in the repository:

```powershell
New-Item -ItemType Directory -Force .tools
curl.exe -fL https://kind.sigs.k8s.io/dl/v0.33.0/kind-windows-amd64 -o .tools/kind.exe
curl.exe -fL https://get.helm.sh/helm-v4.3.1-windows-amd64.zip -o .tools/helm-portable.zip
Expand-Archive .tools/helm-portable.zip .tools/helm-portable -Force
powershell -ExecutionPolicy Bypass -File .\scripts\Setup-Cluster.ps1
```

Setup installs Argo CD v3.5.5 and Kyverno Helm chart 3.9.1 into the isolated `devsecops-demo` kind cluster, using Kubernetes node image `kindest/node:v1.36.1`. It applies only the P9 policy.

The CRD migration hook is disabled for this fresh lab because there are no legacy Kyverno resources to migrate. This also avoids downloading an unnecessary migration-job image.

The GitHub repository is [Jyot-Kikani/devsecops-demo-p9](https://github.com/Jyot-Kikani/devsecops-demo-p9). No Actions secrets or Slack account are required. If using another repository, update `argocd/application.yaml` and the documentation links.

Follow [README.md](README.md) for the demonstration and expected results. Do not push to the original `upstream` remote.

## Image download failures

If the node reports TLS timeouts or ImagePullBackOff, download the same official images through Docker Desktop and import a single-platform archive:

```powershell
docker pull quay.io/argoproj/argocd:v3.5.5
docker image save --platform linux/amd64 -o .tools/argocd.tar quay.io/argoproj/argocd:v3.5.5
.\.tools\kind.exe load image-archive .tools/argocd.tar --name devsecops-demo
```

For Kyverno when this computer cannot download GitHub registry blobs, run the manual **Prepare local cluster images** workflow in GitHub Actions. Download its `p9-cluster-images` artifact and extract `cluster-images.tar` into `.tools/cluster-images/`. The following helper downloads Argo CD, Redis, and Dex through their working official distributions and imports all images as single-platform archives:

```powershell
.\scripts\Import-ClusterImages.ps1
```

The manual workflow stores the archive for one day. After loading images, rerun `scripts/Setup-Cluster.ps1`. No TLS checks are disabled.
