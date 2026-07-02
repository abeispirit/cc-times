#!/bin/bash
# One-shot build script for cc-times (macOS multi-timezone desktop clock).
# Usage: ./build.sh   produces ./cc-times
# (Makefile is the canonical entry point; this is kept for convenience.)
set -e

cd "$(dirname "$0")"

echo "==> building cc-times ..."
# Direct swiftc single-step compile (no SwiftPM network fetch).
# No fixed -target so it builds natively on both Intel and Apple Silicon.
swiftc \
    Sources/*.swift \
    -o cc-times \
    -framework AppKit \
    -framework SwiftUI

echo "==> built: $(pwd)/cc-times"
echo "==> run:   ./cc-times"
