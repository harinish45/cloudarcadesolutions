#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
echo "Project: $PROJECT_ID"
read -r -p "Cloud SQL instance name: " INSTANCE

echo
echo "== INSTANCE =="
gcloud sql instances describe "$INSTANCE"   --format='yaml(name,state,databaseVersion,region,settings.tier)' || true

echo
echo "== DATABASES =="
gcloud sql databases list --instance="$INSTANCE" --format='table(name)' || true

echo
echo "== USERS =="
gcloud sql users list --instance="$INSTANCE" --format='table(name,type)' || true

echo
echo "== API =="
gcloud services list --enabled   --filter='config.name:sqladmin.googleapis.com'   --format='value(config.name)' || true
