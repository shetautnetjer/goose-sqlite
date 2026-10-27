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
# step_done must report an error past a statement's first row.
if "$build/api" step-done-error >"$build/step-done.out" 2>&1; then
    echo "FAIL: step_done missed an error after the first row"; cat "$build/step-done.out"; exit 1
fi
grep -q "integer overflow" "$build/step-done.out" || { echo "FAIL: step_done error text"; cat "$build/step-done.out"; exit 1; }
echo "PASS step_done reports an error after the first row"
