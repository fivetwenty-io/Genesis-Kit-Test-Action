#!/bin/bash

echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"
echo "🔍 DEBUG: Adding explanation comment to pull request"

# Get the PR number - Using a more resilient approach
# First, try to get the PR number from the API
echo "🔍 DEBUG: Fetching PR information"

# Initialize variable to store PR number
PR_NUMBER=""

# Try to get PR info from GitHub API with retry logic
for ATTEMPT in {1..3}; do
  echo "🔍 DEBUG: API fetch attempt $ATTEMPT"
  PR_RESPONSE=$(curl -s -X GET \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=release/v${VERSION}&base=${RELEASE_BRANCH}&state=open")
  
  # Debug: Print the response structure
  echo "🔍 DEBUG: API Response structure:"
  echo "$PR_RESPONSE" | jq 'type' 2>/dev/null || echo "Failed to parse response with jq"
  
  # Check if response is valid and extract PR number
  if echo "$PR_RESPONSE" | jq -e 'if type=="array" and length > 0 then true else false end' >/dev/null 2>&1; then
    PR_NUMBER=$(echo "$PR_RESPONSE" | jq -r '.[0].number // empty')
    if [[ -n "$PR_NUMBER" ]]; then
      echo "🔍 DEBUG: Found PR #$PR_NUMBER"
      break
    fi
  fi
  
  # If we didn't get a PR number and this isn't the last attempt, wait and try again
  if [[ $ATTEMPT -lt 3 ]]; then
    echo "⚠️ API request failed or no PR found. Waiting before retry..."
    sleep 2  # Wait 2 seconds before retrying
  fi
done

# If we still don't have a PR number, try an alternative approach
if [[ -z "$PR_NUMBER" ]]; then
  echo "⚠️ Could not find PR number from API. Checking for PR in environment..."
  
  # Check if there's a PR number from GitHub Actions environment
  if [[ -n "$GITHUB_HEAD_REF" && -n "$GITHUB_BASE_REF" ]]; then
    echo "🔍 DEBUG: Searching for PR using head and base refs"
    # Search for a PR that matches the current head and base refs
    PR_SEARCH=$(curl -s -X GET \
      -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/pulls?head=${GITHUB_HEAD_REF}&base=${GITHUB_BASE_REF}&state=open")
    
    if echo "$PR_SEARCH" | jq -e 'if type=="array" and length > 0 then true else false end' >/dev/null 2>&1; then
      PR_NUMBER=$(echo "$PR_SEARCH" | jq -r '.[0].number // empty')
      echo "🔍 DEBUG: Found PR #$PR_NUMBER via ref search"
    fi
  fi
fi

# If we STILL don't have a PR number, check if it might be in a format we can extract
if [[ -z "$PR_NUMBER" ]]; then
  echo "⚠️ Falling back to check if this is a PR event..."
  # Extract PR number from GitHub event context if this is a PR event
  if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
    PR_NUMBER=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.number // empty')
    echo "🔍 DEBUG: Extracted PR #$PR_NUMBER from event payload"
  fi
fi

# Final fallback - if no PR was found through API, use a default number if provided
if [[ -z "$PR_NUMBER" && -n "$DEFAULT_PR_NUMBER" ]]; then
  echo "⚠️ Using provided default PR number: $DEFAULT_PR_NUMBER"
  PR_NUMBER=$DEFAULT_PR_NUMBER
fi

# If we still don't have a PR number, exit
if [[ -z "$PR_NUMBER" ]]; then
  echo "❌ ERROR: Could not determine PR number. Cannot add comment."
  echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"
  exit 1
fi

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
  
  COMMENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" \
    -d "{
      \"body\": $(echo "$PR_COMMENT" | jq -Rs .)
    }")
  
  # Extract HTTP status code from response
  HTTP_STATUS=$(echo "$COMMENT_RESPONSE" | tail -n1)
  COMMENT_BODY=$(echo "$COMMENT_RESPONSE" | sed '$ d')
  
  if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 300 ]]; then
    echo "✅ Comment added to PR successfully!"
    break
  else
    echo "⚠️ Failed to add comment. HTTP status: $HTTP_STATUS"
    echo "Response: $COMMENT_BODY"
    
    if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
      SLEEP_TIME=$((2 ** $ATTEMPT))  # Exponential backoff: 2, 4, 8 seconds
      echo "Retrying in $SLEEP_TIME seconds..."
      sleep $SLEEP_TIME
    else
      echo "❌ Failed to add comment after $MAX_RETRIES attempts."
      exit 1
    fi
  fi
done

echo "✅ Process completed successfully"
echo "💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬💬"