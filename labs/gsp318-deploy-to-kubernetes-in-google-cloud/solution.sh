#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP318
# Deploy to Kubernetes in Google Cloud Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="valkyrie-cluster"
REPO="valkyrie-docker-repo"

echo "===================================================================="
echo " ☁️  GSP318: Deploy to Kubernetes Automation"
echo " Project: $PROJECT_ID | Cluster: $CLUSTER_NAME | Zone: $ZONE"
echo "===================================================================="

echo "[1/5] Enabling GKE and Artifact Registry APIs..."
gcloud services enable container.googleapis.com artifactregistry.googleapis.com

echo "[2/5] Creating GKE Cluster..."
if ! gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud container clusters create "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --num-nodes=2 \
    --machine-type=e2-medium \
    --release-channel=regular
fi
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"

echo "[3/5] Setting up Artifact Registry..."
if ! gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Docker repository for GSP318"
fi
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "[4/5] Building application container..."
WORK_DIR="${HOME}/valkyrie-app"
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"

cat <<'EOF' > server.js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Valkyrie Application running on GKE! v1.0.0\n');
});
server.listen(8080, () => console.log('Server listening on port 8080'));
EOF

cat <<'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

IMAGE_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/valkyrie-app:v1"
docker build -t "$IMAGE_TAG" .
docker push "$IMAGE_TAG"

echo "[5/5] Deploying Kubernetes manifests..."
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: valkyrie-dev
  labels:
    app: valkyrie
spec:
  replicas: 3
  selector:
    matchLabels:
      app: valkyrie
  template:
    metadata:
      labels:
        app: valkyrie
    spec:
      containers:
      - name: valkyrie-container
        image: ${IMAGE_TAG}
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: valkyrie-dev
spec:
  type: LoadBalancer
  selector:
    app: valkyrie
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

kubectl apply -f deployment.yaml
kubectl rollout status deployment/valkyrie-dev

echo "===================================================================="
echo " ✅ GSP318 GKE Deployment Ready!"
echo " Check Service IP: kubectl get svc valkyrie-dev"
echo "===================================================================="
