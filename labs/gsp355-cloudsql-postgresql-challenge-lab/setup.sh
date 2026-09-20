#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo; echo "ERROR near line $LINENO"; exit 1' ERR

PROJECT_ID="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="us-central1"
INSTANCE="postgres83-psvr9"
DATABASE="orders"
SOURCE_VM="postgres-vm"
NETWORK="default"
MIGRATION_USER="import_admin"
MIGRATION_JOB="gsp355-orders-migration"
SOURCE_PROFILE="gsp355-postgres-vm-source"
DEST_PROFILE="gsp355-postgres83-destination"
PRIVATE_CONNECTION="gsp355-private-connection"
DMS_SUBNET="10.250.0.0/29"

command -v gcloud >/dev/null || { echo "Run this in Google Cloud Shell."; exit 1; }
[[ -n "$PROJECT_ID" ]] || { echo "Set the active lab project first."; exit 1; }
gcloud config set project "$PROJECT_ID" >/dev/null

echo "GSP355 Task 1: standalone PostgreSQL -> existing Cloud SQL"
echo "Project: $PROJECT_ID | Region: $REGION | Instance: $INSTANCE | DB: $DATABASE"

if [[ -z "${DMS_MIGRATION_PASSWORD:-}" ]]; then
  read -r -s -p "Enter the migration user's password: " DMS_MIGRATION_PASSWORD
  echo
fi
[[ -n "$DMS_MIGRATION_PASSWORD" ]] || { echo "Migration password required."; exit 1; }

echo "[1] Enable APIs"
gcloud services enable sqladmin.googleapis.com datamigration.googleapis.com servicenetworking.googleapis.com compute.googleapis.com

echo "[2] Discover postgres-vm"
ZONE="$(gcloud compute instances list --filter="name=$SOURCE_VM" --format='value(zone)' | head -n1)"
[[ -n "$ZONE" ]] || { echo "postgres-vm not found."; exit 1; }
SOURCE_IP="$(gcloud compute instances describe "$SOURCE_VM" --zone="$ZONE" --format='value(networkInterfaces[0].networkIP)')"
PUBLIC_IP="$(gcloud compute instances describe "$SOURCE_VM" --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "Zone=$ZONE InternalIP=$SOURCE_IP ExternalIP=$PUBLIC_IP"

echo "[3] Prepare source PostgreSQL"
gcloud compute ssh "$SOURCE_VM" --zone="$ZONE" --command="sudo apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-14-pglogical"
gcloud compute ssh "$SOURCE_VM" --zone="$ZONE" --command="sudo -u postgres psql -v ON_ERROR_STOP=1 -c \"ALTER SYSTEM SET shared_preload_libraries = 'pglogical';\" -c \"ALTER SYSTEM SET wal_level = 'logical';\" -c \"ALTER SYSTEM SET max_replication_slots = '10';\" -c \"ALTER SYSTEM SET max_wal_senders = '10';\" -c \"ALTER SYSTEM SET max_worker_processes = '10';\""
gcloud compute ssh "$SOURCE_VM" --zone="$ZONE" --command="sudo grep -q '^[[:space:]]*host[[:space:]]\+all[[:space:]]\+all[[:space:]]\+0.0.0.0/0' /etc/postgresql/14/main/pg_hba.conf || echo 'host all all 0.0.0.0/0 scram-sha-256' | sudo tee -a /etc/postgresql/14/main/pg_hba.conf >/dev/null; sudo systemctl restart postgresql"

REMOTE_SQL='CREATE EXTENSION IF NOT EXISTS pglogical;
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='''import_admin''') THEN
   CREATE ROLE import_admin LOGIN PASSWORD '''__DMS_PASSWORD__''';
 ELSE
   ALTER ROLE import_admin LOGIN PASSWORD '''__DMS_PASSWORD__''';
 END IF;
END $$;
ALTER ROLE import_admin WITH REPLICATION;
GRANT CONNECT, CREATE ON DATABASE postgres TO import_admin;
GRANT CONNECT, CREATE ON DATABASE orders TO import_admin;
DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['''distribution_centers''','''inventory_items''','''order_items''','''products''','''users'''] LOOP
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid=format('''public.%s''',t)::regclass AND contype='''p''') THEN
   EXECUTE format('''ALTER TABLE public.%I ADD PRIMARY KEY (id)''',t);
  END IF;
 END LOOP;
END $$;
\c orders
CREATE EXTENSION IF NOT EXISTS pglogical;
GRANT USAGE ON SCHEMA pglogical TO import_admin;
GRANT ALL ON SCHEMA pglogical TO import_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA pglogical TO import_admin;
GRANT USAGE ON SCHEMA public TO import_admin;
GRANT ALL ON SCHEMA public TO import_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO import_admin;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO import_admin;
ALTER TABLE public.distribution_centers OWNER TO import_admin;
ALTER TABLE public.inventory_items OWNER TO import_admin;
ALTER TABLE public.order_items OWNER TO import_admin;
ALTER TABLE public.products OWNER TO import_admin;
ALTER TABLE public.users OWNER TO import_admin;
\c postgres
CREATE EXTENSION IF NOT EXISTS pglogical;
GRANT USAGE ON SCHEMA pglogical TO import_admin;
GRANT ALL ON SCHEMA pglogical TO import_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA pglogical TO import_admin;'
REMOTE_SQL="${REMOTE_SQL//__DMS_PASSWORD__/$DMS_MIGRATION_PASSWORD}"
REMOTE_B64="$(printf '%s' "$REMOTE_SQL" | base64 -w0)"
gcloud compute ssh "$SOURCE_VM" --zone="$ZONE" --command="echo '$REMOTE_B64' | base64 -d | sudo -u postgres psql -v ON_ERROR_STOP=1"

echo "[4] Configure DMS private connectivity"
if ! gcloud database-migration private-connections describe "$PRIVATE_CONNECTION" --region="$REGION" >/dev/null 2>&1; then
  gcloud database-migration private-connections create "$PRIVATE_CONNECTION" --region="$REGION" --display-name="$PRIVATE_CONNECTION" --vpc="$NETWORK" --subnet="$DMS_SUBNET" --no-async
fi
if ! gcloud compute firewall-rules describe allow-gsp355-dms-postgres >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-gsp355-dms-postgres --network="$NETWORK" --allow=tcp:5432 --source-ranges="$DMS_SUBNET" --description="GSP355 DMS PostgreSQL source access"
fi

echo "[5] Create DMS connection profiles"
if ! gcloud database-migration connection-profiles describe "$SOURCE_PROFILE" --region="$REGION" >/dev/null 2>&1; then
  gcloud database-migration connection-profiles create postgresql "$SOURCE_PROFILE" --region="$REGION" --role=SOURCE --host="$SOURCE_IP" --port=5432 --username="$MIGRATION_USER" --password="$DMS_MIGRATION_PASSWORD" --private-connection="$PRIVATE_CONNECTION" --no-async
fi
if ! gcloud database-migration connection-profiles describe "$DEST_PROFILE" --region="$REGION" >/dev/null 2>&1; then
  gcloud database-migration connection-profiles create postgresql "$DEST_PROFILE" --region="$REGION" --cloudsql-instance="$INSTANCE" --role=DESTINATION --display-name="$DEST_PROFILE" --no-async
fi

echo "[6] Create and start continuous migration"
if ! gcloud database-migration migration-jobs describe "$MIGRATION_JOB" --region="$REGION" >/dev/null 2>&1; then
  gcloud database-migration migration-jobs create "$MIGRATION_JOB" --region="$REGION" --type=CONTINUOUS --source="$SOURCE_PROFILE" --destination="$DEST_PROFILE" --databases-filter="$DATABASE" --peer-vpc="projects/$PROJECT_ID/global/networks/$NETWORK" --no-async
fi
gcloud database-migration migration-jobs demote-destination "$MIGRATION_JOB" --region="$REGION" || true
gcloud database-migration migration-jobs verify "$MIGRATION_JOB" --region="$REGION" || true
gcloud database-migration migration-jobs fetch-source-objects "$MIGRATION_JOB" --region="$REGION" || true
STATE="$(gcloud database-migration migration-jobs describe "$MIGRATION_JOB" --region="$REGION" --format='value(state)' 2>/dev/null || true)"
if [[ "$STATE" != "RUNNING" && "$STATE" != "COMPLETED" ]]; then
  gcloud database-migration migration-jobs start "$MIGRATION_JOB" --region="$REGION"
fi

echo
echo "Task 1 setup/start complete."
echo "Monitor: gcloud database-migration migration-jobs describe $MIGRATION_JOB --region=$REGION"
echo "After the migration is ready for promotion, run: bash finish.sh"
