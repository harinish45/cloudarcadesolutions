#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "ERROR near line $LINENO"; exit 1' ERR

command -v gcloud >/dev/null || { echo "Run this in Google Cloud Shell with gcloud installed."; exit 1; }

PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  read -r -p "Qwiklabs project ID: " PROJECT_ID
  gcloud config set project "$PROJECT_ID" >/dev/null
fi

echo "Active project: $PROJECT_ID"

read -r -p "Cloud SQL instance name (exact lab value): " INSTANCE
read -r -p "Region (exact lab value): " REGION
read -r -p "Database name (exact lab value): " DB_NAME
read -r -p "Database user (exact lab value): " DB_USER
read -r -s -p "Database/user password: " DB_PASSWORD; echo
read -r -p "Cloud SQL PostgreSQL version (e.g. POSTGRES_15): " PG_VERSION
PG_VERSION=${PG_VERSION:-POSTGRES_15}

echo
echo "== Enable Cloud SQL Admin API =="
gcloud services enable sqladmin.googleapis.com

echo
echo "== Create Cloud SQL instance if needed =="
if gcloud sql instances describe "$INSTANCE" >/dev/null 2>&1; then
  echo "Instance already exists."
else
  gcloud sql instances create "$INSTANCE" \
    --database-version="$PG_VERSION" \
    --region="$REGION" \
    --tier=db-f1-micro
fi

echo
echo "== Set postgres password =="
gcloud sql users set-password postgres --instance="$INSTANCE" --password="$DB_PASSWORD"

echo
echo "== Create database =="
if gcloud sql databases describe "$DB_NAME" --instance="$INSTANCE" >/dev/null 2>&1; then
  echo "Database already exists."
else
  gcloud sql databases create "$DB_NAME" --instance="$INSTANCE"
fi

echo
echo "== Create/update requested user =="
if gcloud sql users list --instance="$INSTANCE" --format='value(name)' | grep -Fxq "$DB_USER"; then
  gcloud sql users set-password "$DB_USER" --instance="$INSTANCE" --password="$DB_PASSWORD"
else
  gcloud sql users create "$DB_USER" --instance="$INSTANCE" --password="$DB_PASSWORD"
fi

echo
echo "== Final state =="
gcloud sql instances describe "$INSTANCE"   --format='table(name,state,databaseVersion,region,settings.tier)'

echo
echo "== Databases =="
gcloud sql databases list --instance="$INSTANCE" --format='table(name)'

echo
echo "== Users =="
gcloud sql users list --instance="$INSTANCE" --format='table(name,type)'

echo
echo "Base Cloud SQL setup complete. Run: bash verify.sh"
