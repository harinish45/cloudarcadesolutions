#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP049
# Cloud IAM: Qwik Start Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
SA_NAME="iam-demo-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
BUCKET_NAME="${PROJECT_ID}-iam-test"

echo "===================================================================="
echo " ☁️  GSP049: Cloud IAM Automation"
echo " Project: $PROJECT_ID | Service Account: $SA_NAME"
echo "===================================================================="

echo "[1/4] Ensuring storage bucket exists..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location=us-central1
  echo "test content" > test-file.txt
  gcloud storage cp test-file.txt "gs://${BUCKET_NAME}/"
fi

echo "[2/4] Creating test service account..."
if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --display-name="GSP049 Demo SA"
fi

echo "[3/4] Binding roles/storage.objectAdmin to service account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectAdmin" \
  --condition=None \
  --quiet

echo "[4/4] Verifying IAM policy bindings..."
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:${SA_EMAIL}" \
  --format="table(bindings.role)"

echo "===================================================================="
echo " ✅ GSP049 Cloud IAM Setup Verified Successfully!"
echo "===================================================================="
