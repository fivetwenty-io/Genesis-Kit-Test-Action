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

# Check out the default branch and make sure we have the latest
echo "🔍 DEBUG: Checking out the default branch: $default_branch"
git checkout $default_branch
git pull origin $default_branch

# Reset to clean state - remove any non-tracked files
echo "🔍 DEBUG: Resetting repository to clean state"
git reset --hard HEAD
git clean -fdx

# Create version file to ensure we have something to commit
echo "🔍 DEBUG: Creating version file"
echo "v${VERSION}" > VERSION
echo "RELEASE_DATE=\"$(date -u +"%Y-%m-%d")\"" >> VERSION
echo "BUILD_NUMBER=\"${BUILD_NUMBER:-1}\"" >> VERSION

# Check if VERSION file is created
if [[ ! -f "VERSION" ]]; then
  echo "❌ ERROR: VERSION file was not created"
  exit 1
fi

# Check if VERSION file is empty
if [[ ! -s "VERSION" ]]; then
  echo "❌ ERROR: VERSION file is empty"
  exit 1
fi

# Check if there are any changes to commit
if git diff --cached --quiet; then
  echo "❌ ERROR: nothing to commit, working tree clean"
  exit 1
fi

# Stage and commit version file
echo "🔍 DEBUG: Committing version file"
git add VERSION

if [[ "$DEBUG_MODE" == "true" ]]; then
  git commit -m "Prepare release v${VERSION} (debug mode)"
else
  git commit -m "Prepare release v${VERSION}"
fi

# Check for existing release branch or conflicting release/* branches
echo "🔍 DEBUG: Checking for release branch and conflicts"
git fetch --all

# First handle potential conflicts with release/v* branches
if git ls-remote --heads origin | grep -q "refs/heads/release/"; then
  echo "🔍 DEBUG: Found release/* branches that might conflict"
  echo "🔍 DEBUG: Listing potential conflicting branches:"
  git ls-remote --heads origin | grep "refs/heads/release/" || true
  
  # For GitHub, we can't create 'release' if 'release/something' exists
  # We need to delete or rename conflicting branches
  echo "🔍 DEBUG: Attempting to work around conflicts by using a different branch name"
  release_branch="release-branch"
  echo "🔍 DEBUG: Will use '$release_branch' instead of 'release'"
fi

# Now check if our release branch exists
if git ls-remote --heads origin | grep -q "refs/heads/$release_branch"; then
  echo "🔍 DEBUG: Release branch '$release_branch' already exists remotely"
  # Try to fetch it
  git fetch origin $release_branch || echo "🔍 DEBUG: Failed to fetch release branch"
else
  echo "🔍 DEBUG: Creating release branch '$release_branch'"
  # Create the branch locally
  git checkout -b $release_branch
  # Push it to remote
  git push origin $release_branch || {
    echo "🔍 DEBUG: Failed to push release branch, attempting to use main branch as target"
    # If we can't create the branch, we'll just use main as target
    release_branch=$default_branch
    git checkout $default_branch
  }
  # Get back to default branch for changes
  git checkout $default_branch
fi

# Push changes to default branch with improved error handling
echo "🔍 DEBUG: Pushing changes to $default_branch..."
push_attempt=1
max_attempts=3

while [ $push_attempt -le $max_attempts ]; do
  echo "🔍 DEBUG: Push attempt $push_attempt of $max_attempts"
  
  if git push origin $default_branch; then
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
pr_exists=$(gh pr list --head "$default_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --json number --jq 'length')
if [[ "$pr_exists" != "0" ]]; then
  echo "🔍 DEBUG: PR already exists for this release branch, skipping PR creation"
else
  # Prepare PR title and body
  pr_title="Release v${VERSION}"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_title="${pr_title} (MANUAL RELEASE - NO TESTS)"
  fi

  pr_body="Release preparation for version ${VERSION}\n\n"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    pr_body="${pr_body}⚠️ MANUAL RELEASE - TESTING WAS SKIPPED ⚠️\nThis PR was created in debug mode. No automated tests were run.\n\n"
  else
    pr_body="${pr_body}Generated from release commit.\n\n"
  fi
  
  # Add release notes if available
  if [[ -f "release-notes/release-notes.md" ]]; then
    echo "🔍 DEBUG: Found release notes file"
    PR_NOTES=$(cat release-notes/release-notes.md)
    pr_body="${pr_body}${PR_NOTES}"
  else
    echo "🔍 DEBUG: No release notes file found, using generic message"
    pr_body="${pr_body}No release notes available."
  fi

  # Create PR using gh CLI - FROM default branch TO release branch
  echo "🔍 DEBUG: Creating new PR FROM $default_branch TO $release_branch"
  
  # Ensure the committer and author are set to the bot for this PR
  git config --local user.name "Genesis CI Bot"
  git config --local user.email "genesis-ci@example.com"
  
  # Create the PR with the bot identity
  gh pr create \
    --title "$pr_title" \
    --body "$pr_body" \
    --head "$default_branch" \
    --base "$release_branch" \
    --repo "$GITHUB_REPOSITORY" 
fi

echo "✅ Pull request process completed"
echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"