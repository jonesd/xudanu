# syntax=docker/dockerfile:1
# xudanu server image — multi-stage: frontend (vite) + server (rust) + lean runtime.
# Build context must be the repo root (so web/app and original-code are available).

# ── Stage 1: React frontend ────────────────────────────────────────────────
FROM node:22-bookworm-slim AS frontend
WORKDIR /app
COPY web/app/package*.json ./
RUN npm ci
COPY web/app/ ./
RUN npm run build

# ── Stage 2: Rust server binary ────────────────────────────────────────────
FROM rust:1-bookworm-slim AS server
WORKDIR /repo
# Workspace root manifest + the crate (the only workspace member)
COPY Cargo.toml ./
COPY original-code/xanadugold/src-rust ./original-code/xanadugold/src-rust
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/repo/target \
    cargo build --release --features server --bin xudanu-server \
      --manifest-path original-code/xanadugold/src-rust/Cargo.toml && \
    cp /repo/target/release/xudanu-server /xudanu-server

# ── Stage 3: runtime ───────────────────────────────────────────────────────
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
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
