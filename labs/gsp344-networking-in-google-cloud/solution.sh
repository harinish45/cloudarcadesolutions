#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP344
# Networking in Google Cloud Automation (Cloud NAT + VPC Peering)
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
ZONE="us-central1-a"

echo "===================================================================="
echo " ☁️  GSP344: Networking in Google Cloud Automation"
echo " Project: $PROJECT_ID | Region: $REGION | Zone: $ZONE"
echo "===================================================================="

echo "[1/6] Creating VPC Networks..."
if ! gcloud compute networks describe priv-vpc >/dev/null 2>&1; then
  gcloud compute networks create priv-vpc --subnet-mode=custom
fi
if ! gcloud compute networks describe shared-vpc >/dev/null 2>&1; then
  gcloud compute networks create shared-vpc --subnet-mode=custom
fi

echo "[2/6] Creating Subnets with Private Google Access..."
if ! gcloud compute networks subnets describe priv-subnet --region="$REGION" >/dev/null 2>&1; then
  gcloud compute networks subnets create priv-subnet \
    --network=priv-vpc \
    --region="$REGION" \
    --range=10.0.1.0/24 \
    --enable-private-ip-google-access
fi
if ! gcloud compute networks subnets describe shared-subnet --region="$REGION" >/dev/null 2>&1; then
  gcloud compute networks subnets create shared-subnet \
    --network=shared-vpc \
    --region="$REGION" \
    --range=10.0.2.0/24
fi

echo "[3/6] Configuring VPC Peering..."
if ! gcloud compute networks peerings list --network=priv-vpc --format="value(name)" | grep -Fxq "peer-priv-to-shared"; then
  gcloud compute networks peerings create peer-priv-to-shared \
    --network=priv-vpc \
    --peer-network=shared-vpc \
    --auto-create-routes
fi
if ! gcloud compute networks peerings list --network=shared-vpc --format="value(name)" | grep -Fxq "peer-shared-to-priv"; then
  gcloud compute networks peerings create peer-shared-to-priv \
    --network=shared-vpc \
    --peer-network=priv-vpc \
    --auto-create-routes
fi

echo "[4/6] Creating Cloud Router & Cloud NAT..."
if ! gcloud compute routers describe nat-router --region="$REGION" >/dev/null 2>&1; then
  gcloud compute routers create nat-router --network=priv-vpc --region="$REGION"
fi
if ! gcloud compute routers nats describe nat-gateway --router=nat-router --region="$REGION" >/dev/null 2>&1; then
  gcloud compute routers nats create nat-gateway \
    --router=nat-router \
    --region="$REGION" \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges
fi

echo "[5/6] Creating Firewall Rules..."
gcloud compute firewall-rules create allow-priv-ssh --network=priv-vpc --allow=tcp:22 --source-ranges=35.235.240.0/20 2>/dev/null || true
gcloud compute firewall-rules create allow-shared-ssh --network=shared-vpc --allow=tcp:22 --source-ranges=35.235.240.0/20 2>/dev/null || true
gcloud compute firewall-rules create allow-priv-peer-icmp --network=priv-vpc --allow=icmp,tcp:80,tcp:443 --source-ranges=10.0.2.0/24 2>/dev/null || true
gcloud compute firewall-rules create allow-shared-peer-icmp --network=shared-vpc --allow=icmp,tcp:80,tcp:443 --source-ranges=10.0.1.0/24 2>/dev/null || true

echo "[6/6] Creating VM instances..."
if ! gcloud compute instances describe priv-vm --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute instances create priv-vm --zone="$ZONE" --machine-type=e2-medium --subnet=priv-subnet --no-address
fi
if ! gcloud compute instances describe shared-vm --zone="$ZONE" >/dev/null 2>&1; then
  gcloud compute instances create shared-vm --zone="$ZONE" --machine-type=e2-medium --subnet=shared-subnet --no-address
fi

echo "===================================================================="
echo " ✅ GSP344 Networking Resources Ready!"
echo " Verification: SSH via IAP"
echo "   gcloud compute ssh priv-vm --zone=$ZONE --tunnel-through-iap"
echo "===================================================================="
