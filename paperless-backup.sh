#!/usr/bin/env bash
set -euo pipefail

source "paperless-config.sh"

pushd "${PAPERLESS_CONFIG_PATH}" || exit
docker compose exec -T webserver document_exporter ../export

DATE=$(date +%Y-%m-%d)
NAS_PATH="$HOME/fritznas"
STORAGE_PATH="${NAS_PATH}/ASMT-2115-01/paperless"
BACKUP_LOG_FILE="${STORAGE_PATH}/backup-${DATE}.log"

mkdir -p "${NAS_PATH}"
mount "${NAS_PATH}" || exit 1

# rsync backup to NAS
rsync -avz --delete "${PAPERLESS_EXPORT_PATH}" "${STORAGE_PATH}" > "${BACKUP_LOG_FILE}"

umount "${NAS_PATH}"
popd || exit
