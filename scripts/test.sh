#!/usr/bin/env bash
# Standalone package contract tests; no Swan, indexers, or network required.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
cd "$here"
build="${TEST_BUILD_DIR:-$here/.test-build}"
mkdir -p "$build"
export GOOSE_HOME="${GOOSE_HOME:-$build/goose-home}"
"${GOOSE:-goose}" build --offline tests/api.goose -o "$build/api"
"$build/api"
