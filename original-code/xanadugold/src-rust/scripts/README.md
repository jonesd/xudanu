# Xudanu Server Scripts

Helper scripts for building, running, and testing the xudanu server.

All scripts should be run from the project root (`src-rust/`):

```bash
./scripts/<script-name> [options]
```

---

## single.sh

Start a single non-federated xudanu server. Good for local development and testing.

```bash
./scripts/single.sh                    # 127.0.0.1:8080, in-memory (data lost on restart)
./scripts/single.sh 9090               # custom port, in-memory
./scripts/single.sh 9090 /tmp/my-data  # custom port, persistent data
```

**Arguments:**

| Position | Default | Description |
|----------|---------|-------------|
| 1 (port) | `8080` | Port to listen on |
| 2 (data) | *(none)* | Data directory. Omit for in-memory mode. |

**Endpoints:**
- WebSocket: `ws://127.0.0.1:<port>/xudanu`
- Web UI: `http://127.0.0.1:<port>`
- Health: `http://127.0.0.1:<port>/health`

---

## restart.sh

Stop any existing server on the target port, then start fresh with security features enabled (origin checking + CSRF tokens).

```bash
./scripts/restart.sh                     # port 8080, ./data
./scripts/restart.sh 9090                # custom port, ./data
./scripts/restart.sh 9090 /tmp/my-data   # custom port and data dir
```

**Arguments:**

| Position | Default | Description |
|----------|---------|-------------|
| 1 (port) | `8080` | Port to listen on |
| 2 (data) | `./data` | Data directory (created if missing) |

**What it does:**
1. Kills any process on the target port (graceful, then force-kill if needed)
2. Initializes the data directory if it doesn't exist
3. Builds the server
4. Starts with `--allowed-origin http://localhost:<port> --csrf-token`

**Security features enabled:**
- **Origin checking** — only WebSocket upgrades from `http://localhost:<port>` are accepted
- **CSRF tokens** — clients must fetch a token from `/csrf-token` before connecting via WebSocket

---

## federation.sh

Start a federated cluster of N xudanu servers. Each server knows about all others as peers.

```bash
./scripts/federation.sh            # 3 servers on ports 8081-8083
./scripts/federation.sh 5          # 5 servers on ports 8081-8085
./scripts/federation.sh 3 /tmp/fed # 3 servers, custom data base directory
```

**Arguments:**

| Position | Default | Description |
|----------|---------|-------------|
| 1 (count) | `3` | Number of servers (minimum 2) |
| 2 (base) | `/tmp/xudanu-federation` | Base directory. Each server gets a `node-N/` subdirectory. |

**Ports:** Starting from `8081` (node 1 = 8081, node 2 = 8082, etc.)

**Per-node endpoints:**
- Client WebSocket: `ws://127.0.0.1:<port>/xudanu`
- Federation: `ws://127.0.0.1:<port>/federation`
- Health: `http://127.0.0.1:<port>/health`
- Web UI: `http://127.0.0.1:<port>`

**Architecture:**
- Clients connect to exactly one server (pinned, no roaming)
- Servers replicate content to each other via the `/federation` WebSocket
- Grab/release is per-server (no cross-server locking)
- Data persists across restarts in the data directories

---

## caddy.sh

Start xudanu behind a Caddy reverse proxy with HTTPS and HTTP Basic Auth.

```bash
./scripts/caddy.sh              # local dev: https://localhost:8443
./scripts/caddy.sh production   # production: https://yourdomain.com
```

**Arguments:**

| Position | Default | Description |
|----------|---------|-------------|
| 1 (mode) | `local` | `local` for dev, `production` for your domain |

**Environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `XUDANU_DATA_DIR` | *(none)* | Data directory. Omit for in-memory mode. |

**Default credentials (local mode):** `admin` / `changeme`

To change: run `caddy hash-password --plaintext 'newpass'` and update the `Caddyfile`.

**Endpoints (local mode):**
- Web UI: `https://localhost:8443`
- Health: `https://localhost:8443/health`

The xudanu server itself runs on `127.0.0.1:8090` (not directly accessible).

---

## run-tests.sh

Run the xudanu test suite.

```bash
./scripts/run-tests.sh         # all tests: lib + integration + TLS
./scripts/run-tests.sh fast    # lib + integration (skips TLS)
./scripts/run-tests.sh lib     # lib tests only
```

**Arguments:**

| Position | Default | Description |
|----------|---------|-------------|
| 1 (scope) | `all` | `all`, `fast`, or `lib` |

**Test suites:**

| Suite | What it covers |
|-------|---------------|
| **Lib** (~1560 tests) | Unit tests across all modules: crypto, server, CRDT, identity, persistence, transport |
| **Integration** (~199 tests) | End-to-end WebSocket protocol tests |
| **TLS** (7 tests) | TLS handshake and encrypted connection tests |

---

## Common workflows

### First-time setup

```bash
# Build and run a fresh server
./scripts/single.sh 8080 ./data
```

### Daily development

```bash
# Restart with security features after code changes
./scripts/restart.sh

# Run tests
./scripts/run-tests.sh fast
```

### Testing federation

```bash
# Start a 3-node cluster
./scripts/federation.sh

# In another terminal, connect a client to node 1
# ws://127.0.0.1:8081/xudanu
```

### Production-like setup

```bash
# Behind Caddy with HTTPS + auth
./scripts/caddy.sh production
```
