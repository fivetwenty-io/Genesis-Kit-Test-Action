#!/bin/bash
set -e

# Usage: find-hooks.sh <pre|post> <workflow> <job> <step>
# Example: find-hooks.sh pre action build-test build-kit

HOOK_TYPE="$1"   # pre or post
WORKFLOW="$2"    # workflow name (without .yml)
JOB="$3"         # job name with dashes
STEP="$4"        # step name with spaces replaced by dashes

# Replace spaces with dashes in step name
STEP="${STEP// /-}"

# Base pattern for hook scripts
HOOK_PATTERN="${HOOK_TYPE}-${WORKFLOW}_${JOB}_${STEP}"

# Look in both possible locations and output any matching hooks
find "${CI_HOOKS_PATH}" "${ALT_HOOKS_PATH}" -name "${HOOK_PATTERN}*" -type f 2>/dev/null | sort || echo ""