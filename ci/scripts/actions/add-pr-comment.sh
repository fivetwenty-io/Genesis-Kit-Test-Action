#!/bin/bash
set -e

echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"
echo "🔍 DEBUG: Adding explanation comment to pull request"
# Get the PR number from the previous step
echo "🔍 DEBUG: Fetching PR information"
PR_RESPONSE=$(curl -s -X GET \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=release/v${VERSION}&base=${RELEASE_BRANCH}&state=open")

PR_NUMBER=$(echo "$PR_RESPONSE" | jq -r '.[0].number')

if [[ "$PR_NUMBER" == "null" || -z "$PR_NUMBER" ]]; then
  echo "⚠️ Could not find the PR number. Cannot add comment."
  exit 1
fi

echo "🔍 DEBUG: Found PR #$PR_NUMBER"

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

# Create a comment on the PR
echo "🔍 DEBUG: Posting comment to PR #$PR_NUMBER"
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" \
  -d "{
    \"body\": $(echo "$PR_COMMENT" | jq -Rs .)
  }"

echo "✅ Comment added to PR #$PR_NUMBER"
echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"