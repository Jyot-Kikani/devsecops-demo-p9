# P9 verification

Verified on 16 October 2026. This records actual runs, not expected outcomes.

| Demonstration | Observed result | Evidence |
|---|---|---|
| Vulnerable version | Semgrep: 1 SQL injection finding; Hadolint: DL3002; dependency scan: 10 MEDIUM vulnerabilities; image scan: 4 HIGH findings | [Vulnerable run](https://github.com/Jyot-Kikani/devsecops-demo-p9/actions/runs/38871849483) |
| Fake token | Gitleaks failed; Semgrep, Hadolint, dependency scan, and image scan passed | [Secret run](https://github.com/Jyot-Kikani/devsecops-demo-p9/actions/runs/38872103283) |
| Fixed version | All five jobs passed | [Fixed run](https://github.com/Jyot-Kikani/devsecops-demo-p9/actions/runs/38882978127) |
| Image download support | All five security jobs passed after adding the optional image archive workflow | [Support run](https://github.com/Jyot-Kikani/devsecops-demo-p9/actions/runs/38883455300) |
| App behavior | Health endpoint, admin lookup, missing user, and SQL injection input checked successfully | Local `evidence/app-check.txt` |
| Non-root execution | UID and GID 10001; SQLite writes succeeded | Local `evidence/non-root-user.txt` |
| GitOps | Pushed replicas from 2 to 3; Argo CD synchronized commit `4e8661c`; Deployment reached 3/3 ready; application Synced and Healthy | Local `evidence/gitops-replicas.txt` |
| Kyverno rejection | Insecure Deployment update denied by `disallow-root-p9 / autogen-require-non-root` at `/spec/template/spec/securityContext/runAsNonRoot/` | Local `evidence/kyverno-rejected.txt` |
| Kyverno acceptance | Fixed Deployment accepted with exit code 0 | Local `evidence/kyverno-accepted.txt` |
| Cluster components | Argo CD and all four Kyverno controllers running; Kyverno Helm release deployed, revision 4 | Local `evidence/cluster-status.txt` |

The current dependency gate includes MEDIUM/HIGH/CRITICAL findings. The image gate blocks fixable HIGH/CRITICAL findings. A passing run means no findings matching these checks at that time; the checks do not cover every possible security issue.

Local logs and tool/image caches are ignored by Git. No real credentials or Slack integration were used. See README.md for the repeatable demonstration commands.
