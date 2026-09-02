#!/usr/bin/env bash
set -Eeuo pipefail
B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"; for f in portfolio/README.md portfolio/MATRIZ_PROYECTOS.md portfolio/docs/profile-readme.md portfolio/.github/workflows/validar.yml; do test -s "$B/$f"; done; grep -q 'TU_USUARIO.*plantilla' "$B/portfolio/README.md"; echo 'Portfolio local verificado; repos externos no requeridos.'

