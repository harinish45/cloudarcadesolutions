#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP101
# Google Cloud Speech-to-Text API Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

echo "===================================================================="
echo " ☁️  GSP101: Cloud Speech-to-Text API Automation"
echo " Project: $PROJECT_ID"
echo "===================================================================="

echo "[1/4] Enabling Speech API..."
gcloud services enable speech.googleapis.com

echo "[2/4] Generating request JSON payload..."
cat <<'EOF' > request.json
{
  "config": {
    "encoding": "LINEAR16",
    "sampleRateHertz": 16000,
    "languageCode": "en-US"
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/brooklyn_bridge.raw"
  }
}
EOF

echo "[3/4] Calling Speech-to-Text REST endpoint..."
TOKEN="$(gcloud auth print-access-token)"
HTTP_CODE="$(curl -s -o response.json -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data @request.json \
  https://speech.googleapis.com/v1/speech:recognize)"

if [[ "$HTTP_CODE" -ne 200 ]]; then
  echo "[ERROR] API call returned HTTP status $HTTP_CODE" >&2
  cat response.json >&2
  exit 1
fi

echo "[4/4] Validating transcript output..."
cat response.json
echo ""

if grep -q "Brooklyn Bridge" response.json; then
  echo "===================================================================="
  echo " ✅ GSP101 Speech Transcription Verified Successfully!"
  echo "===================================================================="
else
  echo "[WARNING] Expected transcript phrase not found. Verify response above."
fi
