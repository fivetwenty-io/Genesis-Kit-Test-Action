#!/bin/bash
set -e

echo "🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀"
echo "🔍 DEBUG: Starting deployment test to environment $DEPLOY_ENV"
sudo mkdir -p $CI_ROOT/ci/
sudo chmod a+rwx $CI_ROOT/ci/
echo "🔍 DEBUG: Setting up CI scripts and environments"
cp -r $ACTION_PATH/ci/scripts/* $CI_ROOT/ci/ci/scripts/
cp -r ./ci/envs/ $CI_ROOT/ci/envs/

echo "🔍 DEBUG: Launching deployment script"
$ACTION_PATH/ci/scripts/deploy.sh
echo "✅ Deployment and testing completed successfully"
echo "🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀"