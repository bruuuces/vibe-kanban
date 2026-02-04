#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_NAME="vibe-kanban-local-build"
OUT_DIR="${ROOT_DIR}/dist"
CACHE_DIR="${ROOT_DIR}/cache"

mkdir -p "${CACHE_DIR}"

docker buildx build --load \
  -f "${ROOT_DIR}/Dockerfile-local-build" \
  -t "${IMAGE_NAME}" \
  --build-context cache="${CACHE_DIR}" \
  "${ROOT_DIR}"

container_id=$(docker create "${IMAGE_NAME}")
cleanup() {
  docker rm -f "${container_id}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

docker cp "${container_id}:/app/npx-cli/dist" "${OUT_DIR}"

export OUT_DIR
python3 - <<'PY'
import os
import zipfile

root = os.environ["OUT_DIR"]
platform_dirs = [
    d
    for d in os.listdir(root)
    if os.path.isdir(os.path.join(root, d))
]

for platform in platform_dirs:
    zip_path = os.path.join(root, platform, "vibe-kanban.zip")
    if os.path.exists(zip_path):
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(os.path.join(root, platform))
        print(f"extracted {zip_path}")
        break
else:
    raise SystemExit("vibe-kanban.zip not found")
PY
