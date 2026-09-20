#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo; echo "ERROR near line $LINENO"; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
INSTANCE="postgres83-psvr9"
DATABASE="orders"
JOB="gsp355-orders-migration"
CLONE="postgres-orders-pitr"
IAM_USER="student-01-14865d1bb956@qwiklabs.net"
TABLE="inventory_items"

echo "GSP355 Tasks 2–4"
STATE="$(gcloud database-migration migration-jobs describe "$JOB" --region="$REGION" --format='value(state)' 2>/dev/null || true)"
echo "Migration state: $STATE"
if [[ "$STATE" != "COMPLETED" ]]; then
  echo "Promotion is only valid after the migration is ready. Current state: $STATE"
  exit 2
fi

echo "[Task 2] Promote"
gcloud database-migration migration-jobs promote "$JOB" --region="$REGION"

echo "[Task 3] IAM database authentication"
gcloud sql instances patch "$INSTANCE" --database-flags=cloudsql.iam_authentication=on
ZONE="$(gcloud compute instances list --filter='name=postgres-vm' --format='value(zone)' | head -n1)"
PUBLIC_IP="$(gcloud compute instances describe postgres-vm --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"
CURRENT_NETS="$(gcloud sql instances describe "$INSTANCE" --format='value(settings.ipConfiguration.authorizedNetworks[].value)' | paste -sd, -)"
if [[ -n "$CURRENT_NETS" ]]; then NEW_NETS="$CURRENT_NETS,$PUBLIC_IP/32"; else NEW_NETS="$PUBLIC_IP/32"; fi
gcloud sql instances patch "$INSTANCE" --authorized-networks="$NEW_NETS"
if ! gcloud sql users list --instance="$INSTANCE" --format='value(name)' | grep -Fxq "$IAM_USER"; then
  gcloud sql users create "$IAM_USER" --instance="$INSTANCE" --type=cloud_iam_user
fi
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="user:$IAM_USER" --role=roles/cloudsql.instanceUser --quiet >/dev/null

if [[ -z "${CLOUDSQL_POSTGRES_PASSWORD:-}" ]]; then
  read -r -s -p "Enter the Cloud SQL postgres password: " CLOUDSQL_POSTGRES_PASSWORD
  echo
fi
SQL_GRANT="GRANT SELECT ON public.$TABLE TO \"$IAM_USER\";"
printf '%s\n' "$SQL_GRANT" | PGPASSWORD="$CLOUDSQL_POSTGRES_PASSWORD" gcloud sql connect "$INSTANCE" --user=postgres --database="$DATABASE" --quiet

echo "IAM verification command:"
echo "  gcloud sql connect $INSTANCE --auto-iam-authn --user='$IAM_USER' --database='$DATABASE'"
echo "  SELECT COUNT(*) FROM inventory_items;"

echo "[Task 4] Enable PITR"
gcloud sql instances patch "$INSTANCE" --backup-start-time=03:00 --enable-point-in-time-recovery --retained-transaction-log-days=5

TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')"
echo "PITR timestamp: $TIMESTAMP"
SQL_INSERT="INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);"
printf '%s\n' "$SQL_INSERT" | PGPASSWORD="$CLOUDSQL_POSTGRES_PASSWORD" gcloud sql connect "$INSTANCE" --user=postgres --database="$DATABASE" --quiet

if ! gcloud sql instances describe "$CLONE" >/dev/null 2>&1; then
  gcloud sql instances clone "$INSTANCE" "$CLONE" --point-in-time="$TIMESTAMP"
else
  echo "Clone $CLONE already exists."
fi

echo "Tasks 2–4 commands completed. Check the lab score."
