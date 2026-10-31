#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Arcade Solutions - Local CI/CD Validation Runner
# ==============================================================================
set -Eeuo pipefail
trap 'echo "[ERROR] Validation execution failed at line $LINENO." >&2; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "===================================================================="
echo " ☁️  Validating Google Cloud Arcade Solutions Repository"
echo " Repo Root: $REPO_ROOT"
echo "===================================================================="

# 1. Run Python Repository & Markdown Validator
if command -v python3 >/dev/null 2>&1; then
  python3 "${REPO_ROOT}/scripts/validate_labs.py" --path "$REPO_ROOT"
elif command -v python >/dev/null 2>&1; then
  python "${REPO_ROOT}/scripts/validate_labs.py" --path "$REPO_ROOT"
else
  echo "[!] Python is not installed. Skipping python validation script."
fi

# 2. Run Shell Script Syntax Verification (bash -n)
echo ""
echo "[*] Checking syntax of all shell scripts with 'bash -n'..."
find "$REPO_ROOT" -type f -name "*.sh" ! -path "*/.git/*" | while read -r script_file; do
  bash -n "$script_file"
  echo "  [OK] Syntax clean: $(basename "$script_file")"
done

# 3. Run Pytest Suite if present
if command -v pytest >/dev/null 2>&1; then
  echo ""
  echo "[*] Running unit test suite..."
  pytest -v "${REPO_ROOT}/tests"
fi

echo ""
echo "===================================================================="
echo " ✅ All repository validation checks passed successfully!"
echo "===================================================================="
