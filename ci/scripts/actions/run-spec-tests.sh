#!/bin/bash
set -e

echo "🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪"
echo "🔍 DEBUG: Running spec tests with Ginkgo"
sudo chmod -R a+rwx ./*
export PATH=$PATH:~/go/bin

echo "🔍 DEBUG: Changing to spec directory and running tests"
cd spec
echo "🔍 DEBUG: Running ginkgo with params: $GINKGO_PARAMS"
ginkgo $GINKGO_PARAMS .
echo "✅ Spec tests completed successfully"
echo "🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪"