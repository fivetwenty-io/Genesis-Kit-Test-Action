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

# Check if VERSION file is in .gitignore
if [ -f ".gitignore" ]; then
  if grep -q "VERSION" .gitignore; then
    echo "🔍 DEBUG: Warning - VERSION file is in .gitignore, temporarily modifying .gitignore"
    sed -i '/VERSION/d' .gitignore
  fi
fi

# Create version file to ensure we have something to commit
echo "🔍 DEBUG: Creating version file"
echo "v${VERSION}" > VERSION
echo "RELEASE_DATE=\"$(date -u +"%Y-%m-%d")\"" >> VERSION
echo "BUILD_NUMBER=\"${BUILD_NUMBER:-1}\"" >> VERSION

# Verify the file was created
echo "🔍 DEBUG: Verifying VERSION file was created"
if [ ! -f "VERSION" ]; then
  echo "❌ ERROR: Failed to create VERSION file"
  exit 1
fi

# Use force to add the file even if it's ignored
echo "🔍 DEBUG: Force adding VERSION file"
git add -f VERSION

# Check if there are changes to commit now
echo "🔍 DEBUG: Checking git status"
git status

# Check if the file was staged
if ! git diff --cached --quiet; then
  echo "🔍 DEBUG: Changes detected, proceeding with commit"
else
  echo "🔍 DEBUG: No changes detected. Creating an empty commit instead."
  # If no changes, create empty commit
  git commit --allow-empty -m "Prepare release v${VERSION}"
  echo "🔍 DEBUG: Empty commit created"
fi

# Commit if there are changes (this will be skipped if we created an empty commit)
if git diff --cached --quiet; then
  echo "🔍 DEBUG: No changes to commit (already committed with --allow-empty)"
else
  echo "🔍 DEBUG: Committing changes"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    git commit -m "Prepare release v${VERSION} (debug mode)"
  else
    git commit -m "Prepare release v${VERSION}"
  fi
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

# Variable to hold PR number
PR_NUMBER=""

# Check if PR already exists using gh CLI
echo "🔍 DEBUG: Checking if PR already exists"
pr_exists=$(gh pr list --head "$default_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --json number --jq 'length')
if [[ "$pr_exists" != "0" ]]; then
  echo "🔍 DEBUG: PR already exists for this release branch, getting PR number"
  PR_NUMBER=$(gh pr list --head "$default_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --json number --jq '.[0].number')
  echo "🔍 DEBUG: Found existing PR #$PR_NUMBER"
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
  echo "🔍 DEBUG: Creating PR using GitHub CLI"
  gh pr create \
    --title "$pr_title" \
    --body "$pr_body" \
    --head "$default_branch" \
    --base "$release_branch" \
    --repo "$GITHUB_REPOSITORY"
  
  # Get the PR number after creation - GitHub CLI doesn't easily output the number on creation
  echo "🔍 DEBUG: Getting PR number after creation"
  sleep 3  # Brief pause to allow GitHub API to catch up
  PR_NUMBER=$(gh pr list --head "$default_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --limit 1 --json number --jq '.[0].number')
  
  if [[ -n "$PR_NUMBER" ]]; then
    echo "🔍 DEBUG: Created PR #$PR_NUMBER"
  else
    echo "⚠️ Warning: PR was apparently created but couldn't get PR number"
    echo "🔍 DEBUG: Looking up the PR number"
    
    # Try to find the PR number after a short delay to allow GitHub's API to catch up
    sleep 5
    PR_NUMBER=$(gh pr list --head "$default_branch" --base "$release_branch" --repo "$GITHUB_REPOSITORY" --json number --jq '.[0].number')
    
    if [[ -n "$PR_NUMBER" ]]; then
      echo "🔍 DEBUG: Found PR #$PR_NUMBER after lookup"
    else
      echo "⚠️ Warning: Couldn't find PR number, but continuing anyway"
    fi
  fi
fi

echo "✅ Pull request process completed"

# Only proceed with commenting if we have a PR number
if [[ -n "$PR_NUMBER" ]]; then
  echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"
  echo "🔍 DEBUG: Adding explanation comment to pull request #$PR_NUMBER"
  
  # Read the comment template file or use default if not found
  echo "🔍 DEBUG: Looking for PR comment template"
  if [[ -f "$PR_COMMENT_FILE" ]]; then
    PR_COMMENT=$(cat "$PR_COMMENT_FILE")
    echo "🔍 DEBUG: Using comment template from file"
  else
    # Default comment if template file doesn't exist
    echo "🔍 DEBUG: Template file not found, using default comment"
    if [[ "$DEBUG_MODE" == "true" ]]; then
      PR_COMMENT="# Manual Release Process for ${KIT_NAME} v${VERSION}

      This PR was manually created in debug mode for version ${VERSION}.
      
      ## ⚠️ IMPORTANT: No automated tests were run! ⚠️
      
      ## What happens next:
      1. Review the changes
      2. Run any necessary manual tests before merging
      3. Approve and merge this PR to complete the release
      4. The GitHub release will be automatically created after merging
      
      ## Breaking Changes
      Testing was skipped, so no automated breaking change detection was performed.
      Please review changes manually before merging."
    else
      # Default comment if template file doesn't exist and not in debug mode
      PR_COMMENT="# Release Process for ${KIT_NAME} v${VERSION}

      This PR was automatically created as part of the release process for version ${VERSION}.
      
      ## What happens next:
      1. Review the changes and release notes
      2. Run any additional manual tests if needed
      3. Approve and merge this PR to complete the release
      4. The GitHub release will be automatically created after merging
      
      ## Breaking Changes
      $(grep -A 5 "BREAKING CHANGE" spec-check/diff-* 2>/dev/null || echo "No breaking changes detected")
      
      For more information, see the [release documentation](https://your-docs-link)."
    fi
    echo "🔍 DEBUG: Default comment template prepared"
  fi

  # Replace placeholders in the comment
  echo "🔍 DEBUG: Replacing placeholders in comment template"
  PR_COMMENT=${PR_COMMENT//\{\{VERSION\}\}/$VERSION}
  PR_COMMENT=${PR_COMMENT//\{\{KIT_NAME\}\}/$KIT_NAME}

  # Create a comment on the PR with retry logic
  echo "🔍 DEBUG: Posting comment to PR #$PR_NUMBER"
  MAX_RETRIES=3
  for ATTEMPT in $(seq 1 $MAX_RETRIES); do
    echo "🔍 DEBUG: Comment posting attempt $ATTEMPT"
    
    # Using gh CLI for comment posting for better reliability
    if gh pr comment "$PR_NUMBER" --body "$PR_COMMENT" --repo "$GITHUB_REPOSITORY"; then
      echo "✅ Comment added to PR successfully"
      break
    else
      echo "⚠️ Failed to add comment using gh CLI"
      
      # Fallback to curl if gh CLI fails
      echo "🔍 DEBUG: Trying curl as fallback for attempt $ATTEMPT"
      COMMENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" \
        -d "{
          \"body\": $(echo "$PR_COMMENT" | jq -Rs .)
        }")
      
      # Extract HTTP status code from response
      HTTP_STATUS=$(echo "$COMMENT_RESPONSE" | tail -n1)
      COMMENT_BODY=$(echo "$COMMENT_RESPONSE" | sed '$ d')
      
      if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 300 ]]; then
        echo "✅ Comment added to PR successfully via curl!"
        break
      else
        echo "⚠️ Failed to add comment via curl. HTTP status: $HTTP_STATUS"
        
        if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
          SLEEP_TIME=$((2 ** $ATTEMPT))  # Exponential backoff: 2, 4, 8 seconds
          echo "Retrying in $SLEEP_TIME seconds..."
          sleep $SLEEP_TIME
        else
          echo "⚠️ Failed to add comment after $MAX_RETRIES attempts, but continuing workflow"
          # Don't exit with error - we want the workflow to continue even if comment fails
        fi
      fi
    fi
  done
  echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"
else
  echo "⚠️ No PR number found, skipping comment addition"
fi

echo "🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄"