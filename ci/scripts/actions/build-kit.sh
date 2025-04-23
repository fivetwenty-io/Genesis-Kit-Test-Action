#!/bin/bash
set -e

echo "🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️"
echo "🔍 DEBUG: Starting kit build process for $KIT_NAME v$KIT_VERSION"
sudo chmod -R a+rwx ./*
echo "🔍 DEBUG: Permissions updated for working directory"

# Install common tools
./setup-tools.sh

echo "🔍 DEBUG: Compiling kit..."
genesis compile-kit --force -v "$KIT_VERSION" -n "$KIT_NAME"

echo "🔍 DEBUG: Setting up build directory"
sudo mkdir -p $BUILD_ROOT/
sudo chmod -R a+rwx $BUILD_ROOT/
cp ./$KIT_NAME-$KIT_VERSION.tar.gz $BUILD_ROOT/

echo "🔍 DEBUG: Build directory contents:"
ls -lah $BUILD_ROOT/
echo "✅ Build completed successfully"
echo "🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️🏗️"