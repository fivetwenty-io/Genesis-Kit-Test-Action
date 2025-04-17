#!/bin/bash
set -e

echo "🔍 DEBUG: Checking for breaking changes in comparison results"
if grep -q "BREAKING CHANGE" spec-check/diff-*; then
  echo "⚠️ BREAKING CHANGES DETECTED! ⚠️"
  echo "has_breaking_changes=true" >> $GITHUB_OUTPUT
else
  echo "✅ No breaking changes detected"
  echo "has_breaking_changes=false" >> $GITHUB_OUTPUT
fi