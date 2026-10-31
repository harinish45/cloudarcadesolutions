# GSP318: Deploy to Kubernetes in Google Cloud — Technical Notes

## 💡 GKE & Container Best Practices

### 1. Artifact Registry vs Container Registry (gcr.io)
- `gcr.io` (Container Registry) is deprecated. **Google Artifact Registry** (`pkg.dev`) is the unified artifact store supporting Docker, Helm, Maven, npm, and Python packages.
- Regional endpoints (e.g. `us-central1-docker.pkg.dev`) ensure container images reside in the same region as the GKE worker nodes for fast image pull times and zero cross-region egress charges.

### 2. GKE Standard vs Autopilot
- **GKE Autopilot**: Google manages the entire underlying cluster infrastructure including node provisioning, auto-scaling, OS patching, and security hardening. You pay strictly per pod resource requests (`cpu`, `memory`).
- **GKE Standard**: You manage node pools, machine shapes, daemonsets, and OS images with complete cluster configuration flexibility.

### 3. Kubernetes Rolling Updates & Readiness Probes
- Default `RollingUpdate` strategy maintains `maxSurge: 25%` and `maxUnavailable: 25%`.
- Containers should define `readinessProbe` to ensure traffic is only routed when application listeners are fully initialized.
