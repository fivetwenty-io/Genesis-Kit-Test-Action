#!/bin/bash
set -e

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"
echo "🔍 DEBUG: Creating pull request for release v${VERSION}"
git config --global user.name "Genesis CI Bot"
git config --global user.email "genesis-ci@example.com"
echo "🔍 DEBUG: Git user configured as Genesis CI Bot"

# Create release branch if it doesn't exist
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

# Push branch with debug information
echo "🔍 DEBUG: Attempting to push branch to origin..."
echo "🔍 DEBUG: Branch name: $release_branch"
echo "🔍 DEBUG: Repository: $GITHUB_REPOSITORY"

# Attempt push with error capture
push_output=$(git push --set-upstream https://$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY $release_branch 2>&1) || {
  echo "⚠️ Push failed with error:"
  echo "$push_output"
  echo "🔍 DEBUG: Checking if remote exists..."
  git remote -v
  echo "🔍 DEBUG: Checking branch status..."
  git status
  exit 1
}

echo "✅ Branch pushed successfully"

# Check if PR already exists
echo "🔍 DEBUG: Checking if PR already exists"
PR_EXISTS=$(curl -s -X GET \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=release/v${VERSION}&base=${RELEASE_BRANCH}&state=open" | jq length)

if [[ "$PR_EXISTS" -gt 0 ]]; then
  echo "🔍 DEBUG: PR already exists for this release branch, skipping PR creation"
else
  # Create PR if it doesn't exist
  echo "🔍 DEBUG: Creating new PR for release"
  pr_title="Release v${VERSION}"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_title="${pr_title} (MANUAL RELEASE - NO TESTS)"
  fi
  
  pr_body="Release preparation for version ${VERSION}

  $(if [[ "$DEBUG_MODE" == "true" ]]; then
    echo "⚠️ MANUAL RELEASE - TESTING WAS SKIPPED ⚠️"
    echo "This PR was created in debug mode. No automated tests were run."
  else
    echo "Generated from release commit."
  fi)

  $(cat release-notes/release-notes.md 2>/dev/null || echo "No release notes available.")"
  
  # Create PR
  echo "🔍 DEBUG: Sending PR creation request to GitHub API"
  curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls" \
    -d '{
      "title": "'"${pr_title}"'",
      "body": "'"${pr_body}"'",
      "head": "'"${release_branch}"'",
      "base": "'"${RELEASE_BRANCH}"'"
    }'
fi
echo "✅ Pull request process completed"
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"