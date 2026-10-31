#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP315
# Perform Foundational Infrastructure Tasks in Google Cloud Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${LAB_REGION:-us-east1}"
BUCKET_NAME="${PROJECT_ID}-media-bucket"
TOPIC_NAME="memories-topic"
FUNCTION_NAME="memories-function"
INACTIVE_USER="${TARGET_USER:-}"

echo "===================================================================="
echo " ☁️  GSP315: Foundational Infrastructure Tasks Automation"
echo " Project: $PROJECT_ID | Region: $REGION | Bucket: $BUCKET_NAME"
echo "===================================================================="

echo "[1/5] Enabling Cloud Functions, Eventarc, Cloud Build, and Run APIs..."
gcloud services enable \
  cloudfunctions.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com

echo "[2/5] Creating Cloud Storage bucket..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --uniform-bucket-level-access
fi

echo "[3/5] Creating Pub/Sub topic and subscription..."
if ! gcloud pubsub topics describe "$TOPIC_NAME" >/dev/null 2>&1; then
  gcloud pubsub topics create "$TOPIC_NAME"
fi
if ! gcloud pubsub subscriptions describe "${TOPIC_NAME}-sub" >/dev/null 2>&1; then
  gcloud pubsub subscriptions create "${TOPIC_NAME}-sub" --topic="$TOPIC_NAME"
fi

echo "[4/5] Deploying Cloud Function (Gen 2)..."
WORK_DIR="${HOME}/gsp315-cf"
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"

cat <<'JS' > index.js
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('processMessage', cloudEvent => {
  const base64Data = cloudEvent.data.message.data;
  const messageString = base64Data ? Buffer.from(base64Data, 'base64').toString() : 'Empty payload';
  console.log(`[EVENT RECEIVED] Message payload: ${messageString}`);
});
JS

cat <<'JSON' > package.json
{
  "name": "foundational-cf",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.3.0"
  }
}
JSON

gcloud functions deploy "$FUNCTION_NAME" \
  --gen2 \
  --region="$REGION" \
  --runtime=nodejs20 \
  --entry-point=processMessage \
  --source=. \
  --trigger-topic="$TOPIC_NAME" \
  --max-instances=5 \
  --quiet

echo "[5/5] Checking IAM user revocation..."
if [[ -n "$INACTIVE_USER" ]]; then
  echo "Revoking role for user: $INACTIVE_USER"
  gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
    --member="user:${INACTIVE_USER}" \
    --role="roles/viewer" 2>/dev/null || true
fi

echo "===================================================================="
echo " ✅ GSP315 Automation Completed!"
echo " Testing event pipeline:"
echo "   gcloud pubsub topics publish $TOPIC_NAME --message='Verification ping'"
echo "===================================================================="
