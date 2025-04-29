#!/bin/bash
set -e

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"
echo "🔍 DEBUG: Creating pull request for release v${VERSION}"

# Configure git user
git config --global user.name "Genesis CI Bot"
git config --global user.email "genesis-ci@example.com"
echo "🔍 DEBUG: Git user configured as Genesis CI Bot"

# Token debugging and setup
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "🔍 DEBUG: GITHUB_TOKEN is not set"
  exit 1
else
  echo "🔍 DEBUG: GITHUB_TOKEN length is ${#GITHUB_TOKEN}"
fi

# Use the GH CLI for authentication instead of modifying the remote URL
# This is more reliable as it handles token authentication properly
echo "🔍 DEBUG: Setting up GitHub CLI authentication"
export GH_TOKEN="$GITHUB_TOKEN"

release_branch="release/v${VERSION}"
echo "🔍 DEBUG: Working with release branch: $release_branch"

# Check if release branch exists remotely
echo "🔍 DEBUG: Checking if release branch already exists"
if git ls-remote --heads origin $release_branch | grep -q $release_branch; then
  echo "🔍 DEBUG: Release branch $release_branch already exists, checking it out"
  git fetch origin
  git checkout $release_branch || git checkout -b $release_branch origin/$release_branch
else
  echo "🔍 DEBUG: Creating new release branch $release_branch"
  git checkout -b $release_branch
fi

# Commit changes if any
echo "🔍 DEBUG: Adding and committing changes"
git add -A
if [[ "$DEBUG_MODE" == "true" ]]; then
  git commit -m "Prepare release v${VERSION} (debug mode)" || echo "🔍 DEBUG: No changes to commit"
else
  git commit -m "Prepare release v${VERSION}" || echo "🔍 DEBUG: No changes to commit"
fi

# Push branch with improved error handling
echo "🔍 DEBUG: Attempting to push branch to origin..."
push_attempt=1
max_attempts=3

while [ $push_attempt -le $max_attempts ]; do
  echo "🔍 DEBUG: Push attempt $push_attempt of $max_attempts"
  
  if gh repo sync ${GITHUB_REPOSITORY} --branch $release_branch --force; then
    echo "🔍 DEBUG: Branch pushed successfully using gh repo sync"
    break
  elif git push --set-upstream origin $release_branch; then
    echo "🔍 DEBUG: Branch pushed successfully using git push"
    break
  elif [ $push_attempt -lt $max_attempts ]; then
    echo "🔍 DEBUG: Push failed, waiting 5 seconds before retry..."
    sleep 5
  else
    echo "❌ ERROR: Failed to push branch after $max_attempts attempts"
    exit 1
  fi
  
  push_attempt=$((push_attempt + 1))
done

# Check if PR already exists using gh CLI
echo "🔍 DEBUG: Checking if PR already exists"
if gh pr list --head "$release_branch" --base "$RELEASE_BRANCH" --repo "$GITHUB_REPOSITORY" --json number --jq 'length' | grep -qv '^0$'; then
  echo "🔍 DEBUG: PR already exists for this release branch, skipping PR creation"
else
  # Prepare PR title and body
  pr_title="Release v${VERSION}"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_title="${pr_title} (MANUAL RELEASE - NO TESTS)"
  fi

  if [[ -f "release-notes/release-notes.md" ]]; then
    echo "🔍 DEBUG: Found release notes file"
    PR_NOTES=$(cat release-notes/release-notes.md)
  else
    echo "🔍 DEBUG: No release notes file found, using generic message"
    PR_NOTES="No release notes available."
  fi

  pr_body="Release preparation for version ${VERSION}\n\n"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_body="${pr_body}⚠️ MANUAL RELEASE - TESTING WAS SKIPPED ⚠️\nThis PR was created in debug mode. No automated tests were run.\n\n"
  else
    pr_body="${pr_body}Generated from release commit.\n\n"
  fi
  pr_body="${pr_body}${PR_NOTES}"

  # Create PR using gh CLI
  echo "🔍 DEBUG: Creating new PR for release"
  gh pr create \
    --title "$pr_title" \
    --body "$pr_body" \
    --head "$release_branch" \
    --base "$RELEASE_BRANCH" \
    --repo "$GITHUB_REPOSITORY"
fi

echo "✅ Pull request process completed"
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"