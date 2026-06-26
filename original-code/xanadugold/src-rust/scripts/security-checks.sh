#!/bin/bash
# Rust security checks for this repository.
#
# Usage:
#   ./scripts/security-checks.sh all
#   ./scripts/security-checks.sh audit
#   ./scripts/security-checks.sh deny
#   ./scripts/security-checks.sh clippy
#   ./scripts/security-checks.sh sonar-prep
#   ./scripts/security-checks.sh sonar-scan
#   ./scripts/security-checks.sh install-tools

set -e

cd "$(dirname "$0")/.."

MODE="${1:-all}"

print_step() {
    echo ""
    echo "=== $1 ==="
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

ensure_cargo_tool() {
    local cmd="$1"
    local crate="$2"

    if have_cmd "$cmd"; then
        return
    fi

    echo "Missing '$cmd'. Installing '$crate' with cargo..."
    cargo install "$crate"

    if ! have_cmd "$cmd"; then
        echo "ERROR: '$cmd' is still unavailable after install."
        echo "       Ensure \$HOME/.cargo/bin is on PATH."
        exit 1
    fi
}

run_audit() {
    print_step "cargo audit"
    ensure_cargo_tool cargo-audit cargo-audit
    cargo audit -D warnings
}

run_deny() {
    print_step "cargo deny"
    ensure_cargo_tool cargo-deny cargo-deny
    cargo deny check advisories bans sources
}

run_clippy() {
    print_step "cargo clippy (strict)"
    cargo clippy --workspace --all-targets --all-features -- -D warnings
}

run_sonar_prep() {
    print_step "Generate Sonar Rust reports"
    mkdir -p target/sonar
    cargo clippy --workspace --all-targets --all-features --message-format=json > target/sonar/clippy.json
    echo "Wrote target/sonar/clippy.json"
}

run_sonar_scan() {
    print_step "SonarScanner"

    if ! have_cmd sonar-scanner; then
        echo "ERROR: sonar-scanner is not installed."
        echo "       Install SonarScanner CLI and rerun."
        exit 1
    fi

    if [ -z "${SONAR_HOST_URL:-}" ] || [ -z "${SONAR_TOKEN:-}" ]; then
        echo "ERROR: SONAR_HOST_URL and SONAR_TOKEN must be set."
        echo "Example:"
        echo "  export SONAR_HOST_URL=https://sonarcloud.io"
        echo "  export SONAR_TOKEN=<token>"
        exit 1
    fi

    run_sonar_prep

    sonar-scanner \
        -Dsonar.host.url="${SONAR_HOST_URL}" \
        -Dsonar.token="${SONAR_TOKEN}"
}

install_tools() {
    print_step "Install cargo security tools"
    ensure_cargo_tool cargo-audit cargo-audit
    ensure_cargo_tool cargo-deny cargo-deny
    echo "cargo-audit and cargo-deny are installed."
}

case "$MODE" in
    all)
        run_audit
        run_deny
        run_clippy
        ;;
    audit)
        run_audit
        ;;
    deny)
        run_deny
        ;;
    clippy)
        run_clippy
        ;;
    sonar-prep)
        run_sonar_prep
        ;;
    sonar-scan)
        run_sonar_scan
        ;;
    install-tools)
        install_tools
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Valid modes: all | audit | deny | clippy | sonar-prep | sonar-scan | install-tools"
        exit 1
        ;;
esac

echo ""
echo "Done."