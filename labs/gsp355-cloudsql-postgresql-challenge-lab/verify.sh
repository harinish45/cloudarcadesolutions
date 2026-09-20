#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
REGION="us-central1"
INSTANCE="postgres83-psvr9"
JOB="gsp355-orders-migration"
echo "Project: $PROJECT_ID"
echo "== Cloud SQL =="
gcloud sql instances describe "$INSTANCE" --format='yaml(name,state,databaseVersion,region,settings.backupConfiguration,settings.databaseFlags,settings.ipConfiguration.authorizedNetworks)' || true
echo "== Migration job =="
gcloud database-migration migration-jobs describe "$JOB" --region="$REGION" || true
echo "== DMS profiles =="
gcloud database-migration connection-profiles list --region="$REGION" || true
