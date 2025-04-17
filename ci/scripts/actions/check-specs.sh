#!/bin/bash
set -e

echo "🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍"
echo "🔍 DEBUG: Checking for breaking changes in specs"
mkdir -p spec-check
echo "🔍 DEBUG: Created spec-check directory"

# Get the most recent tag
echo "🔍 DEBUG: Fetching tags"
git fetch --tags
PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ -n "$PREV_TAG" ]]; then
  echo "🔍 DEBUG: Found previous tag: $PREV_TAG"
  echo "🔍 DEBUG: Checking out previous tag to compare specs"
  git checkout $PREV_TAG
  cp -r spec/results ./spec-check/old-specs
  git checkout -
else
  echo "🔍 DEBUG: No previous tag found, this appears to be the initial release"
fi

results_file="${GITHUB_WORKSPACE}/spec-check/diff-$(date -u +%Y%m%d%H%M%S)"
if [[ -n "$PREV_TAG" ]]; then
  echo "🔍 DEBUG: Generating spec comparison results"
  echo "Comparing specs with previous release $PREV_TAG" > "$results_file"
  $ACTION_PATH/ci/scripts/compare-release-specs.sh "$PREV_TAG" >> "$results_file"
else
  echo "🔍 DEBUG: No comparison needed for initial release"
  echo "Initial release - no spec changes to compare" > "$results_file"
fi
echo "✅ Spec comparison completed"
echo "🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍"