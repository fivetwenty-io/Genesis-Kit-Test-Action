#!/bin/bash
set -e

echo "📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝"
echo "🔍 DEBUG: Generating release notes"
mkdir -p release-notes
echo "🔍 DEBUG: Running release notes script for version $VERSION"
$ACTION_PATH/ci/scripts/release-notes.sh \
  "$VERSION" \
  "$(pwd)" \
  "$PREV_TAG" \
  "release-notes/$RELEASE_NOTES_FILE"
echo "✅ Release notes generated"
echo "📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝📝"