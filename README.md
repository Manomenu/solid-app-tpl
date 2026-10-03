# myapp

<!-- template:start -->
## Starting a project from this template

This is **solid-app-tpl**: an empty FastAPI + React app with the whole quality gate, the
container stack and the Helm chart already wired, and no features yet.

```sh
cp -r ~/repos/solid-app-tpl ~/repos/<name> && cd ~/repos/<name>
rm -rf .git .venv myapp_web/node_modules && git init -b master
./scripts/init-project.sh <name> [port-offset]   # renames myapp → <name>, shifts ports, deletes itself
just check
```

Then set `image.registry` in `deploy/chart/values.yaml` and add the project to the platform
repo. This section disappears with `init-project.sh`.
<!-- template:end -->

## Requirements

`uv`, `pnpm` (via corepack), `just`, `podman` with `podman compose`; for the full gate also
`helm` and `shellcheck`.

## Everyday commands

```sh
just                 # every recipe, grouped
just db up           # local PostgreSQL on :5523
just server          # API on :6290 (Swagger at /docs)
just web             # web app on :3290, proxies /api to the server
just up              # the whole stack in containers on :8099 — no cluster needed
just check           # the quality gate, exactly what CI runs
just e2e             # browser tests against a real server and database
just secrets backup  # copy the local .env files into Bitwarden (restore on a new machine)
```

How the repo is organised and what every change must bring along: [AGENTS.md](AGENTS.md).
