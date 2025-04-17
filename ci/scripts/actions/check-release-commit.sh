#!/bin/bash
set -e

echo "🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎"
echo "🔍 DEBUG: Checking if this is a release commit"
# Get the last commit message
commit_msg=$(git log -1 --pretty=%B)
echo "🔍 DEBUG: Last commit message: $commit_msg"

# Check if it matches a release pattern
if [[ $commit_msg =~ [Rr][Ee][Ll][Ee][Aa][Ss][Ee][^0-9]*([0-9]+\.[0-9]+\.[0-9]+) ]]; then
  echo "🔍 DEBUG: ✓ This IS a release commit"
  echo "is_release=true" >> $GITHUB_OUTPUT
  echo "version=${BASH_REMATCH[1]}" >> $GITHUB_OUTPUT
  echo "✅ Detected release commit for version ${BASH_REMATCH[1]}"
else
  echo "🔍 DEBUG: ✗ This is NOT a release commit"
  echo "is_release=false" >> $GITHUB_OUTPUT
  echo "version=" >> $GITHUB_OUTPUT
  echo "ℹ️ Not a release commit"
fi
echo "🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎🔎"