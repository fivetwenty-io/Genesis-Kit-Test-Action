#!/bin/bash
set -e

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"
echo "🔍 DEBUG: Checking current version from version file"
if [[ -f version ]]; then
  version=$(cat version | grep -oP '(?<=Version: ).*' || echo "0.0.0")
  echo "🔍 DEBUG: Found version: $version"
  echo "current_version=$version" >> $GITHUB_OUTPUT
else
  echo "🔍 DEBUG: No version file found, defaulting to 0.0.0"
  echo "current_version=0.0.0" >> $GITHUB_OUTPUT
fi
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"