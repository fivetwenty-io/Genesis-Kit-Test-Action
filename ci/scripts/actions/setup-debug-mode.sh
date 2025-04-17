#!/bin/bash
set -e

echo "🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞"
echo "🔍 DEBUG: Running in DEBUG MODE - Setting up without tests"
mkdir -p spec-check
mkdir -p release-notes
echo "🔍 DEBUG: Created directories for spec checks and release notes"
echo "⚠️ Debug mode enabled - skipping tests and proceeding directly to PR creation"

# Create placeholder files for spec checks
echo "🔍 DEBUG: Creating placeholder files for spec checks"
echo "SKIPPED IN DEBUG MODE" > spec-check/diff-$(date -u +%Y%m%d%H%M%S)

# Create placeholder for release notes
echo "🔍 DEBUG: Creating placeholder release notes"
echo "# Release Notes for $KIT_NAME v$VERSION" > release-notes/release-notes.md
echo "Generated in debug mode - no automated tests were run." >> release-notes/release-notes.md
echo "✅ Debug mode setup completed"

# Set breaking changes flag to false in debug mode
echo "🔍 DEBUG: Setting breaking changes flag to false in debug mode"
echo "has_breaking_changes=false" >> $GITHUB_OUTPUT
echo "ℹ️ Breaking changes detection skipped in debug mode"
echo "🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞🐞"