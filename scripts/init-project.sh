#!/usr/bin/env bash
# Turns a fresh copy of this template into a project of its own, once:
#
#   ./scripts/init-project.sh <name> [port-offset]
#
#   name          lowercase letters, digits, "_" (e.g. grzyby): becomes <name>_server,
#                 <name>_web, the database, the containers and the chart.
#   port-offset   0–8, default 1. Every project gets its own local ports, so several run side
#                 by side: server 6200+10n, web 3200+10n, e2e 6201/3201+10n, database
#                 5433+10n, compose 8090+n. automat-operat uses 0; the template itself sits
#                 on 9 (6290, 3290, 5523, 8099) so it never collides with a real project.
#
# It rewrites names and ports, regenerates the lockfiles, then deletes itself — after that
# the project owes nothing to the template.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-}"
OFFSET="${2:-1}"

[[ "$NAME" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "usage: $0 <name> [port-offset 0-9] — name: lowercase, digits, _" >&2; exit 2; }
[[ "$OFFSET" =~ ^[0-8]$ ]] || { echo "port-offset must be 0–8" >&2; exit 2; }
[ -d "$ROOT/myapp_server" ] || { echo "already initialised (no myapp_server/)" >&2; exit 1; }


cd "$ROOT"
DASHED="${NAME//_/-}"

# Every tracked-to-be text file, minus lockfiles and the generated API types (regenerated below).
mapfile -t FILES < <(grep -rlI --exclude-dir={.git,.venv,node_modules,.artifacts} \
    --exclude={uv.lock,pnpm-lock.yaml,openapi.d.ts,init-project.sh} -e myapp -e 6290 -e 3290 -e 5523 -e 8099 .)

perl -pi -e "
    s/\\bmyapp_(server|web|e2e|test)\\b/${NAME}_\$1/g;
    s/\\bmyapp-(server|web|postgres)\\b/${DASHED}-\$1/g;
    s/\\bMYAPP_/\\U${NAME}\\E_/g;
    s/myapp/${NAME}/g;
    s/\\b6290\\b/$((6200 + 10 * OFFSET))/g; s/\\b6291\\b/$((6201 + 10 * OFFSET))/g;
    s/\\b3290\\b/$((3200 + 10 * OFFSET))/g; s/\\b3291\\b/$((3201 + 10 * OFFSET))/g;
    s/\\b5523\\b/$((5433 + 10 * OFFSET))/g; s/\\b8099\\b/$((8090 + OFFSET))/g;
" "${FILES[@]}"
# The chart and package names use dashes; the Python package name in pyproject too.
perl -pi -e "s/\\b${NAME}-server\\b/${DASHED}-server/g; s/^name = \"${NAME}\"/name = \"${DASHED}\"/" pyproject.toml myapp_server/pyproject.toml
perl -pi -e "s/^name: ${NAME}\$/name: ${DASHED}/" deploy/chart/Chart.yaml

mv myapp_server/myapp_server "myapp_server/${NAME}_server"
mv myapp_server "${NAME}_server"
mv myapp_web "${NAME}_web"

rm -rf .venv "${NAME}_web/node_modules"
uv lock -q && uv sync -q
(cd "${NAME}_web" && pnpm install --silent)
./scripts/.internal/api-types.sh >/dev/null
# The pre-commit hook (gitleaks), when the copy already is a git repo.
[ -d .git ] && git config core.hooksPath .githooks

# The template's own instructions go with it.
perl -0pi -e 's/<!-- template:start -->.*?<!-- template:end -->\n?//s' README.md
rm -- "$0"
echo "initialised ${NAME}: next \`just check\`, then set image.registry in deploy/chart/values.yaml"
