#!/usr/bin/env bash
set -euo pipefail

echo "sourcing paperless-config.sh"
source "paperless-config.sh"

echo "exporting documents"
pushd "${PAPERLESS_CONFIG_PATH}" || exit
docker compose exec -T webserver document_exporter ../export

DATE=$(date +%Y-%m-%d)
NAS_PATH="$HOME/fritznas"
STORAGE_PATH="${NAS_PATH}/ASMT-2115-01/paperless"
BACKUP_LOG_FILE="${STORAGE_PATH}/backup-${DATE}.log"

echo "mounting NAS"
mkdir -p "${NAS_PATH}"
mount "${NAS_PATH}" || exit 1

echo "copying documents to NAS"
rsync -avz --progress --delete "${PAPERLESS_EXPORT_PATH}" "${STORAGE_PATH}" | tee "${BACKUP_LOG_FILE}"

echo "unmounting NAS"
umount "${NAS_PATH}"
popd || exit
