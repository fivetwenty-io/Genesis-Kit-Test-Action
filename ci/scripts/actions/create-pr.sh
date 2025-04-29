#!/bin/bash
set -e

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"
echo "🔍 DEBUG: Creating pull request for release v${VERSION}"

# Configure git user
git config --global user.name "Genesis CI Bot"
git config --global user.email "genesis-ci@example.com"
echo "🔍 DEBUG: Git user configured as Genesis CI Bot"

# Configure authentication for git operations
# Using environment variables for authentication is more secure
export GIT_ASKPASS="/bin/echo"
export GIT_USERNAME="x-access-token"
export GIT_PASSWORD="$TOKEN"

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

# Push branch with enhanced error handling
echo "🔍 DEBUG: Attempting to push branch to origin..."
echo "🔍 DEBUG: Branch name: $release_branch"
echo "🔍 DEBUG: Repository: $GITHUB_REPOSITORY"
echo "🔍 DEBUG: Current git status:"
git status

# Verify GitHub access before pushing
echo "🔍 DEBUG: Verifying GitHub API access..."
gh_status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $TOKEN" https://api.github.com/user)
if [[ "$gh_status" != "200" ]]; then
  echo "⚠️ GitHub API access failed with status code: $gh_status"
  echo "🔍 DEBUG: GitHub token may be invalid or expired"
  exit 1
fi
echo "🔍 DEBUG: GitHub API access verified (status code: $gh_status)"

# List remotes for debugging
echo "🔍 DEBUG: Configured remotes:"
git remote -v

# Attempt push with verbose output and error capture
echo "🔍 DEBUG: Beginning push operation with verbose output..."
if ! git push -v --set-upstream origin $release_branch 2>&1; then
  echo "⚠️ Push failed with error"
  echo "🔍 DEBUG: Checking if there are network issues..."
  ping -c 3 github.com || echo "⚠️ Network connectivity to GitHub may be an issue"
  
  echo "🔍 DEBUG: Attempting push with force option as fallback..."
  if ! git push -v --force-with-lease --set-upstream origin $release_branch 2>&1; then
    echo "⚠️ Force push also failed, exiting"
    exit 1
  else
    echo "✅ Force push succeeded"
  fi
else
  echo "✅ Branch pushed successfully"
fi

# Check if PR already exists
echo "🔍 DEBUG: Checking if PR already exists"
PR_EXISTS=$(curl -s -X GET \
  -H "Authorization: token $TOKEN" \
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
  
  # Prepare release notes
  if [[ -f "release-notes/release-notes.md" ]]; then
    echo "🔍 DEBUG: Found release notes file"
    PR_NOTES=$(cat release-notes/release-notes.md)
  else
    echo "🔍 DEBUG: No release notes file found, using generic message"
    PR_NOTES="No release notes available."
  fi
  
  # Escape newlines and quotes for JSON
  PR_NOTES_ESCAPED=$(echo "$PR_NOTES" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
  
  # Create PR body
  pr_body="Release preparation for version ${VERSION}\\n\\n"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_body="${pr_body}⚠️ MANUAL RELEASE - TESTING WAS SKIPPED ⚠️\\n"
    pr_body="${pr_body}This PR was created in debug mode. No automated tests were run.\\n\\n"
  else
    pr_body="${pr_body}Generated from release commit.\\n\\n"
  fi
  pr_body="${pr_body}${PR_NOTES_ESCAPED}"
  
  # Create PR with proper error handling
  echo "🔍 DEBUG: Sending PR creation request to GitHub API"
  PR_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls" \
    -d '{
      "title": "'"${pr_title}"'",
      "body": "'"${pr_body}"'",
      "head": "'"${release_branch}"'",
      "base": "'"${RELEASE_BRANCH}"'"
    }')
  
  # Check if PR was created successfully
  PR_URL=$(echo "$PR_RESPONSE" | jq -r .html_url)
  if [[ "$PR_URL" == "null" ]]; then
    echo "⚠️ Failed to create PR. GitHub API response:"
    echo "$PR_RESPONSE" | jq .
    exit 1
  else
    echo "✅ Pull request created successfully: $PR_URL"
  fi
fi

echo "✅ Pull request process completed"
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"