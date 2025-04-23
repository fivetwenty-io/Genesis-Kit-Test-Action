#!/bin/bash
set -e

echo "⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡"
echo "🔍 DEBUG: Starting setup process for Genesis Kit Build & Test"
echo "⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡"

# Install common tools
echo "🔍 DEBUG: Installing common tools"
sudo apt-get update
sudo apt-get install -y build-essential unzip jq

# Echo GitHub Action path
echo "🔍 DEBUG: GitHub Action path: ${GITHUB_ACTION_PATH}"

echo "🔍 DEBUG: Contents of GitHub Action path:"
ls -la "${GITHUB_ACTION_PATH}"

echo "🔍 DEBUG: Contents of GitHub Action path ./ci:"
ls -la "${GITHUB_ACTION_PATH}/ci"

echo "🔍 DEBUG: Contents of GitHub Action path ./ci/scripts:
ls -la ${GITHUB_ACTION_PATH}/ci/scripts"

echo "🔍 DEBUG: Contents of GitHub Action path /var/run/act/actions/:"
ls -la /var/run/act/actions/

# Install Genesis dependencies
echo "🔍 DEBUG: Updating permissions for scripts"
sudo chmod -R a+rwx "${GITHUB_ACTION_PATH}/ci/scripts/*"
echo "✅ Permissions updated for scripts"

echo "🔍 DEBUG: Installing Genesis and dependencies"
"${GITHUB_ACTION_PATH}/ci/scripts/ensure-tools.sh"
echo "✅ Genesis and deps installed successfully"
echo "⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡"