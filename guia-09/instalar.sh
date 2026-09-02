#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"; for c in docker k3d kubectl jq; do command -v "$c" >/dev/null || { echo "Falta $c" >&2; exit 69; }; done; chmod +x "$B/operaciones.sh" "$B/scripts/"*.sh "$B/backend/entrypoint.sh"; command -v yamllint >/dev/null && yamllint -d relaxed "$B/manifests" >/dev/null || true
