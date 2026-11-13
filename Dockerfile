# syntax=docker/dockerfile:1
# xudanu server image — multi-stage: frontend (vite) + server (rust) + lean runtime.
# Build context must be the repo root (so web/app and original-code are available).

# ── Stage 1: React frontend + classic reader ──────────────────────────────
FROM node:22-bookworm-slim AS frontend
WORKDIR /app
COPY web/app/package*.json ./
RUN npm ci
COPY web/app/ ./
RUN npm run build
# Classic reader: built separately, merged into the app dist AFTER the
# app build (vite empties dist/ on build, so classic must come last).
# Mirrors scripts/pre-push.sh's rsync; without this the image serves no
# /classic/ and the classic-first landing dead-ends (found 2026-11-12:
# production /classic/index.html was an empty file for this reason).
COPY web/classic/package*.json ./classic-src/
RUN cd classic-src && npm ci
COPY web/classic/ ./classic-src/
RUN cd classic-src && npm run build && cp -r dist /app/dist/classic

# ── Stage 2: Rust server binary ────────────────────────────────────────────
FROM rust:slim AS server
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /repo
# Workspace root manifest + lockfile (reproducible builds) + the crate (the only workspace member)
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
COPY original-code/xanadugold/src-rust ./original-code/xanadugold/src-rust
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/repo/target \
    cargo build --release --features server --bin xudanu-server \
      --manifest-path original-code/xanadugold/src-rust/Cargo.toml && \
    cp /repo/target/release/xudanu-server /xudanu-server

# ── Stage 3: runtime ───────────────────────────────────────────────────────
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=server /xudanu-server /usr/local/bin/xudanu-server
COPY --from=frontend /app/dist /app/dist

# 8080 = HTTP (web UI + API + client WS) and the /federation peer WS
EXPOSE 8080
VOLUME ["/data"]
ENTRYPOINT ["xudanu-server"]
# Default: standalone single-machine node. Federation is enabled at runtime
# via `--peer` / `--federation-mode` (see docker-compose.yml).
CMD ["run", "0.0.0.0:8080", "/data", "--static-dir", "/app/dist"]
