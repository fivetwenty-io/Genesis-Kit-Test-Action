#!/bin/bash
set -e

echo "🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢"
echo "🔍 DEBUG: Calculating new version according to bump type: $VERSION_BUMP"
current="$CURRENT_VERSION"
echo "🔍 DEBUG: Current version: $current"

# Extract version components
major=$(echo "$current" | cut -d. -f1)
minor=$(echo "$current" | cut -d. -f2)
patch=$(echo "$current" | cut -d. -f3)
echo "🔍 DEBUG: Extracted components: major=$major, minor=$minor, patch=$patch"

# Bump version according to type
case "$VERSION_BUMP" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    echo "🔍 DEBUG: Performing MAJOR version bump"
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    echo "🔍 DEBUG: Performing MINOR version bump"
    ;;
  patch|*)
    patch=$((patch + 1))
    echo "🔍 DEBUG: Performing PATCH version bump"
    ;;
esac

new_version="${major}.${minor}.${patch}"
echo "🔍 DEBUG: New version: $new_version"
echo "new_version=${new_version}" >> $GITHUB_OUTPUT
echo "previous_version=$current" >> $GITHUB_OUTPUT

# Update version file
echo "🔍 DEBUG: Updating version file"
echo "## Version: ${new_version}" > version
echo "✅ Version file updated to $new_version"
echo "🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢🔢"