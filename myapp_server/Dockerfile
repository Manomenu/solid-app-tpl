# Build context is the SOLUTION ROOT, not this directory: the root uv.lock is the only
# lockfile in the repo, and uv needs the workspace manifest next to it.
#
#   podman build -f myapp_server/Dockerfile -t myapp-server .

FROM docker.io/library/python:3.14-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.12.5 /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Manifests first — this layer is the expensive one and it only rebuilds when a
# dependency moves. Every workspace member's pyproject.toml has to be present or uv
# fails to discover the workspace, including members this image never installs.
COPY pyproject.toml uv.lock ./
COPY myapp_server/pyproject.toml myapp_server/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-workspace --package myapp-server

# Then the sources, which change every commit.
COPY myapp_server/ myapp_server/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable --package myapp-server


FROM docker.io/library/python:3.14-slim

RUN useradd --system --create-home --uid 10001 app

COPY --from=builder --chown=app:app /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
# Settings derive the solution root from __file__, which only holds for the editable
# install used in development. Here it is a wheel under site-packages, so the root has to
# be stated outright or the .env lookup climbs into site-packages.
ENV MYAPP_SOLUTION_ROOT=/app

USER app
WORKDIR /app
EXPOSE 6290

# Reuses the module entry point the dev script runs, so host and port stay one contract.
CMD ["python", "-m", "myapp_server"]
