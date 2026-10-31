#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP330
# Implement Load Balancing on Compute Engine Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
ZONE="us-central1-a"
TEMPLATE="lb-backend-template"
MIG="lb-backend-group"
HC="http-basic-check"
BACKEND_SVC="lb-backend-service"
URL_MAP="http-lb-url-map"
PROXY="http-lb-proxy"
FW_RULE="http-lb-forwarding-rule"

echo "===================================================================="
echo " ☁️  GSP330: Cloud Load Balancing Automation"
echo " Project: $PROJECT_ID | Region: $REGION | Zone: $ZONE"
echo "===================================================================="

echo "[1/6] Creating instance template..."
if ! gcloud compute instance-templates describe "$TEMPLATE" >/dev/null 2>&1; then
  gcloud compute instance-templates create "$TEMPLATE" \
    --region="$REGION" \
    --network=default \
    --subnet=default \
    --tags=allow-health-check \
    --machine-type=e2-micro \
    --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install -y apache2
cat <<EOF > /var/www/html/index.html
<h1>GSP330 Web Server</h1>
<p>Served from instance: $(hostname)</p>
EOF
systemctl restart apache2
'
fi

echo "[2/6] Creating Managed Instance Group..."
if ! gcloud compute instance-groups managed describe "$MIG" --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute instance-groups managed create "$MIG" \
    --template="$TEMPLATE" \
    --size=2 \
    --zone="$ZONE"
fi

gcloud compute instance-groups managed set-named-ports "$MIG" \
  --named-ports=http:80 \
  --zone="$ZONE"

echo "[3/6] Creating health check firewall rule..."
if ! gcloud compute firewall-rules describe fw-allow-health-check >/dev/null 2>&1; then
  gcloud compute firewall-rules create fw-allow-health-check \
    --network=default \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-health-check \
    --rules=tcp:80
fi

echo "[4/6] Creating health check and backend service..."
if ! gcloud compute health-checks describe "$HC" >/dev/null 2>&1; then
  gcloud compute health-checks create http "$HC" \
    --port=80 \
    --check-interval=5s \
    --healthy-threshold=2 \
    --unhealthy-threshold=2
fi

if ! gcloud compute backend-services describe "$BACKEND_SVC" --global >/dev/null 2>&1; then
  gcloud compute backend-services create "$BACKEND_SVC" \
    --protocol=HTTP \
    --port-name=http \
    --health-checks="$HC" \
    --global

  gcloud compute backend-services add-backend "$BACKEND_SVC" \
    --instance-group="$MIG" \
    --instance-group-zone="$ZONE" \
    --balancing-mode=UTILIZATION \
    --max-utilization=0.8 \
    --capacity-scaler=1 \
    --global
fi

echo "[5/6] Creating URL map, proxy, and forwarding rule..."
if ! gcloud compute url-maps describe "$URL_MAP" >/dev/null 2>&1; then
  gcloud compute url-maps create "$URL_MAP" --default-service="$BACKEND_SVC"
fi

if ! gcloud compute target-http-proxies describe "$PROXY" >/dev/null 2>&1; then
  gcloud compute target-http-proxies create "$PROXY" --url-map="$URL_MAP"
fi

if ! gcloud compute forwarding-rules describe "$FW_RULE" --global >/dev/null 2>&1; then
  gcloud compute forwarding-rules create "$FW_RULE" \
    --load-balancing-scheme=EXTERNAL_MANAGED \
    --network-tier=PREMIUM \
    --address-ip-version=IPV4 \
    --ports=80 \
    --target-http-proxy="$PROXY" \
    --global
fi

echo "[6/6] Fetching Load Balancer IP..."
LB_IP="$(gcloud compute forwarding-rules describe "$FW_RULE" --global --format='value(IPAddress)')"
echo "===================================================================="
echo " ✅ Load Balancer Deployed at: http://${LB_IP}"
echo " Note: Backends require ~2-3 minutes to pass health checks."
echo "===================================================================="
