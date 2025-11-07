#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_FILE="${ROOT_DIR}/patches/stake-burn.patch"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "Patch file not found: ${PATCH_FILE}" >&2
  exit 1
fi

apply_patch() {
  local target_dir="$1"

  if [[ ! -d "${target_dir}" ]]; then
    echo "Target directory does not exist: ${target_dir}" >&2
    exit 1
  fi

  pushd "${target_dir}" >/dev/null

  if git apply --check "${PATCH_FILE}" >/dev/null 2>&1; then
    git apply "${PATCH_FILE}"
    echo "Applied stake/burn patch in ${target_dir}"
  elif git apply --reverse --check "${PATCH_FILE}" >/dev/null 2>&1; then
    echo "Stake/burn patch already applied in ${target_dir}, skipping"
  else
    echo "Failed to apply stake/burn patch in ${target_dir}" >&2
    exit 1
  fi

  popd >/dev/null
}

apply_patch "${ROOT_DIR}/salvium"
