#!/bin/zsh
# Runs the checks in tests/. Run: zsh scripts/test.sh
set -e
cd "$(dirname "$0")/.."
swift run --scratch-path "$HOME/Library/Caches/duck-build" DuckChecks 2>&1 | grep -vE "ld: warning|^\[|Building|Build (complete|of product)"
