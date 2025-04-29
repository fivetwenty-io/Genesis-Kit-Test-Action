#!/bin/bash
set -e

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"
echo "🔍 DEBUG: Creating pull request for release v${VERSION}"
echo "🔍 DEBUG: REPO: ${GITHUB_REPOSITORY}"

# Token debugging and setup
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "🔍 DEBUG: GITHUB_TOKEN is not set"
  exit 1
else
  echo "🔍 DEBUG: GITHUB_TOKEN length is ${#GITHUB_TOKEN}"
fi

# Set up GitHub CLI authentication
echo "🔍 DEBUG: Setting up GitHub CLI authentication"
export GH_TOKEN="$GITHUB_TOKEN"

# Set git user info through GitHub CLI
echo "🔍 DEBUG: Configuring user information"
gh api --method PUT /user --field name="Genesis CI Bot" --field email="genesis-ci@example.com" || echo "🔍 DEBUG: Could not set user info via API, using git config"
# Fallback to git config if API call fails
git config --global user.name "Genesis CI Bot"
git config --global user.email "genesis-ci@example.com"
echo "🔍 DEBUG: User configured as Genesis CI Bot"

release_branch="release"
default_branch=$(gh api repos/${GITHUB_REPOSITORY} --jq '.default_branch')
echo "🔍 DEBUG: Default branch is: $default_branch"
echo "🔍 DEBUG: Release branch is: $release_branch"

# Clone the repository using GitHub CLI if not already in it
echo "🔍 DEBUG: Ensuring we have the latest repository code"
if [ ! -d ".git" ]; then
  gh repo clone ${GITHUB_REPOSITORY} . || echo "🔍 DEBUG: Already in repository directory"
fi

# Check out the default branch
echo "🔍 DEBUG: Checking out the default branch: $default_branch"
git checkout $default_branch
git pull origin $default_branch

# Reset to clean state - remove any non-tracked files
echo "🔍 DEBUG: Resetting repository to clean state"
git reset --hard HEAD
git clean -fdx

# Prepare a temporary branch for the PR
temp_branch="temp-release-v${VERSION}"
echo "🔍 DEBUG: Creating temporary branch: $temp_branch"
git checkout -b $temp_branch

# Stage necessary files only (add specific file patterns here if needed)
# For example: git add src/ package.json version.txt
# This is empty for now since we're only creating a PR to trigger the release pipeline

# Create commit with minimal changes if needed
if [[ "$DEBUG_MODE" == "true" ]]; then
  # Create an empty commit or a specific version bump commit
  git commit --allow-empty -m "Prepare release v${VERSION} (debug mode)"
else
  # Create an empty commit or a specific version bump commit
  git commit --allow-empty -m "Prepare release v${VERSION}"
fi

# Push branch with improved error handling
echo "🔍 DEBUG: Attempting to push temporary branch to origin..."
push_attempt=1
max_attempts=3

while [ $push_attempt -le $max_attempts ]; do
  echo "🔍 DEBUG: Push attempt $push_attempt of $max_attempts"
  
  if git push --set-upstream origin $temp_branch --force; then
    echo "🔍 DEBUG: Branch pushed successfully"
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
if gh pr list --head "$temp_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --json number --jq 'length' | grep -qv '^0$'; then
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

  # Create PR using gh CLI - FROM default branch TO release branch
  echo "🔍 DEBUG: Creating new PR FROM $temp_branch TO $release_branch"
  gh pr create \
    --title "$pr_title" \
    --body "$pr_body" \
    --head "$temp_branch" \
    --base "$release_branch" \
    --repo "$GITHUB_REPOSITORY"
fi

echo "✅ Pull request process completed"
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"