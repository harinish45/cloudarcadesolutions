#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP313
# Set Up a Google Cloud Network Automation
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Lab execution failed at line $LINENO" >&2; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
VPC_NAME="taw-custom-network"

echo "===================================================================="
echo " ☁️  GSP313: Set Up a Google Cloud Network Automation"
echo " Project: $PROJECT_ID | Network: $VPC_NAME"
echo "===================================================================="

echo "[1/4] Creating custom VPC network..."
if ! gcloud compute networks describe "$VPC_NAME" >/dev/null 2>&1; then
  gcloud compute networks create "$VPC_NAME" --subnet-mode=custom
  echo "[+] Custom VPC created."
else
  echo "[*] Custom VPC already exists."
fi

echo "[2/4] Creating subnets..."
if ! gcloud compute networks subnets describe subnet-alpha --region=us-east1 >/dev/null 2>&1; then
  gcloud compute networks subnets create subnet-alpha \
    --network="$VPC_NAME" \
    --region=us-east1 \
    --range=10.10.10.0/24
fi

if ! gcloud compute networks subnets describe subnet-beta --region=us-central1 >/dev/null 2>&1; then
  gcloud compute networks subnets create subnet-beta \
    --network="$VPC_NAME" \
    --region=us-central1 \
    --range=10.10.20.0/24
fi

if ! gcloud compute networks subnets describe subnet-mgmt --region=us-central1 >/dev/null 2>&1; then
  gcloud compute networks subnets create subnet-mgmt \
    --network="$VPC_NAME" \
    --region=us-central1 \
    --range=10.10.30.0/24
fi

echo "[3/4] Creating firewall rules..."
if ! gcloud compute firewall-rules describe nw-allow-internal >/dev/null 2>&1; then
  gcloud compute firewall-rules create nw-allow-internal \
    --network="$VPC_NAME" \
    --action=ALLOW \
    --direction=INGRESS \
    --rules=all \
    --source-ranges=10.10.0.0/16
fi

if ! gcloud compute firewall-rules describe nw-allow-icmp >/dev/null 2>&1; then
  gcloud compute firewall-rules create nw-allow-icmp \
    --network="$VPC_NAME" \
    --action=ALLOW \
    --direction=INGRESS \
    --rules=icmp \
    --source-ranges=0.0.0.0/0
fi

if ! gcloud compute firewall-rules describe nw-allow-ssh-bastion >/dev/null 2>&1; then
  gcloud compute firewall-rules create nw-allow-ssh-bastion \
    --network="$VPC_NAME" \
    --action=ALLOW \
    --direction=INGRESS \
    --rules=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=bastion
fi

echo "[4/4] Creating Compute Engine instances..."
if ! gcloud compute instances describe vm-internal-1 --zone=us-east1-b >/dev/null 2>&1; then
  gcloud compute instances create vm-internal-1 \
    --zone=us-east1-b \
    --machine-type=e2-micro \
    --subnet=subnet-alpha \
    --no-address
fi

if ! gcloud compute instances describe vm-internal-2 --zone=us-central1-a >/dev/null 2>&1; then
  gcloud compute instances create vm-internal-2 \
    --zone=us-central1-a \
    --machine-type=e2-micro \
    --subnet=subnet-beta \
    --no-address
fi

if ! gcloud compute instances describe vm-bastion --zone=us-central1-a >/dev/null 2>&1; then
  gcloud compute instances create vm-bastion \
    --zone=us-central1-a \
    --machine-type=e2-micro \
    --subnet=subnet-mgmt \
    --tags=bastion
fi

echo "===================================================================="
echo " ✅ GSP313 Resources Provisioned Successfully!"
echo " Test command:"
echo "   gcloud compute ssh vm-bastion --zone=us-central1-a"
echo "===================================================================="
