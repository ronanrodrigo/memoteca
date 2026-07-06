#!/bin/bash
# run-tests.sh — Run tests in the target repo
# Usage: make test

set -euo pipefail

echo "🧪 Running tests..."

if [ -f "package.json" ]; then
  # Check if there are test scripts
  if grep -q '"test"' package.json; then
    npm test
  else
    echo "⚠️ No test script found in package.json"
  fi
elif [ -f "Makefile" ]; then
  # Try running make test in the target repo
  make test
else
  echo "❌ No tests configured. Add package.json or Makefile with a test target."
  exit 1
fi

echo "✅ Tests completed!"
