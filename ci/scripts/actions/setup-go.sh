#!/bin/bash
set -e

echo "🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪"
echo "🔍 DEBUG: Setting up Go for spec tests"
echo "🔍 DEBUG: Using Go version: $GO_VERSION"
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $GO_VERSION
echo "🔍 DEBUG: Installing Ginkgo test framework"
go install github.com/onsi/ginkgo/v2/ginkgo@latest
export PATH=$PATH:~/go/bin
echo "✅ Go setup completed"
go version
echo "🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪"