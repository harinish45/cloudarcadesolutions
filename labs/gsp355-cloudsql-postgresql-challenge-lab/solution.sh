#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solution - GSP355
# Cloud SQL PostgreSQL Challenge Lab: Master Orchestration Runner
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO." >&2; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-all}"

print_banner() {
  echo "===================================================================="
  echo " ☁️  GSP355: Cloud SQL PostgreSQL Challenge Lab Automation"
  echo "===================================================================="
}

show_help() {
  cat <<'EOF'
Usage: bash solution.sh [COMMAND]

Commands:
  setup     Run Task 1: Source DB prep, DMS connection profiles, start migration
  finish    Run Tasks 2-4: Promote DB, configure IAM authn, enable PITR & clone
  all       Run setup, wait for CDC synchronization readiness, then run finish
  status    Check current status of DMS migration job and Cloud SQL instance
  help      Display this help dialog
EOF
}

check_status() {
  local project_id="${DEVSHELL_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
  local region="us-central1"
  local job="gsp355-orders-migration"
  local instance="postgres83-psvr9"

  echo "[*] Checking Cloud SQL instance status..."
  gcloud sql instances describe "$instance" --format="table(name,state,databaseVersion,region)" 2>/dev/null || echo "Cloud SQL instance not found yet."

  echo "[*] Checking DMS migration job status..."
  gcloud database-migration migration-jobs describe "$job" --region="$region" --format="table(name,state,phase,type)" 2>/dev/null || echo "Migration job not found yet."
}

case "$ACTION" in
  setup)
    print_banner
    echo "[*] Executing Task 1: Setup and start migration..."
    bash "${SCRIPT_DIR}/setup.sh"
    ;;
  finish)
    print_banner
    echo "[*] Executing Tasks 2-4: Promotion, IAM Auth, PITR & Clone..."
    bash "${SCRIPT_DIR}/finish.sh"
    ;;
  status)
    print_banner
    check_status
    ;;
  all)
    print_banner
    echo "[*] Step 1: Starting Database Migration Service setup..."
    bash "${SCRIPT_DIR}/setup.sh"
    echo ""
    echo "[*] Step 2: Waiting for CDC synchronization..."
    echo "[!] Once the migration state transitions to RUNNING/CDC in Cloud Console,"
    echo "    execute: bash solution.sh finish"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Unknown command: $ACTION" >&2
    show_help
    exit 1
    ;;
esac
