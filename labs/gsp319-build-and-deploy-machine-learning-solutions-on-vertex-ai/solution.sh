#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP319
# Build and Deploy Machine Learning Solutions on Vertex AI Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-vertex-ml"
MODEL_NAME="penguin-classifier"
ENDPOINT_NAME="penguin-endpoint"

echo "===================================================================="
echo " ☁️  GSP319: Vertex AI MLOps Automation"
echo " Project: $PROJECT_ID | Region: $REGION"
echo "===================================================================="

echo "[1/6] Enabling Vertex AI & Compute APIs..."
gcloud services enable \
  aiplatform.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com

echo "[2/6] Training baseline Scikit-Learn model..."
WORK_DIR="${HOME}/vertex-ml"
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"

python3 -m pip install -q scikit-learn joblib

cat <<'PY' > train.py
import joblib
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier

X, y = load_iris(return_X_y=True)
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X, y)
joblib.dump(clf, "model.joblib")
print("Model serialized.")
PY

python3 train.py

echo "[3/6] Storing model artifact in Cloud Storage..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION"
fi
gcloud storage cp model.joblib "gs://${BUCKET_NAME}/model/model.joblib"

echo "[4/6] Registering model in Vertex AI Model Registry..."
if ! gcloud ai models list --region="$REGION" --filter="displayName=${MODEL_NAME}" --format="value(name)" | grep -q .; then
  gcloud ai models upload \
    --region="$REGION" \
    --display-name="$MODEL_NAME" \
    --container-image-uri="us-docker.pkg.dev/vertex-ai/prediction/sklearn-cpu.1-3:latest" \
    --artifact-uri="gs://${BUCKET_NAME}/model/"
fi

MODEL_ID="$(gcloud ai models list --region="$REGION" --filter="displayName=${MODEL_NAME}" --format="value(name)" | head -n1)"
echo "[+] Model ID: $MODEL_ID"

echo "[5/6] Creating Vertex AI Endpoint..."
if ! gcloud ai endpoints list --region="$REGION" --filter="displayName=${ENDPOINT_NAME}" --format="value(name)" | grep -q .; then
  gcloud ai endpoints create \
    --region="$REGION" \
    --display-name="$ENDPOINT_NAME"
fi

ENDPOINT_ID="$(gcloud ai endpoints list --region="$REGION" --filter="displayName=${ENDPOINT_NAME}" --format="value(name)" | head -n1)"
echo "[+] Endpoint ID: $ENDPOINT_ID"

echo "[6/6] Deploying Model to Endpoint..."
if ! gcloud ai endpoints describe "$ENDPOINT_ID" --region="$REGION" --format="value(deployedModels[0].id)" 2>/dev/null | grep -q .; then
  gcloud ai endpoints deploy-model "$ENDPOINT_ID" \
    --region="$REGION" \
    --model="$MODEL_ID" \
    --display-name="deployed-${MODEL_NAME}" \
    --machine-type="n1-standard-2" \
    --min-replica-count=1 \
    --max-replica-count=1 \
    --traffic-split=0=100
fi

echo "===================================================================="
echo " ✅ Vertex AI Model Deployed!"
echo " Test with:"
echo "   gcloud ai endpoints predict $ENDPOINT_ID --region=$REGION --json-request=instances.json"
echo "===================================================================="
