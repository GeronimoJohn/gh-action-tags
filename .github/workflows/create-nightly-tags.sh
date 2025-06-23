#!/bin/bash
set -e

# Function to create tag for a branch
create_tag_for_branch() {
    local branch_type=$1
    local branch_name=$2
    
    git checkout "$branch_name"
    
    PKG_VERSION=$(cat ./package.json | grep '"version":' | sed 's/[^0-9.]//g')
    COMMIT_DATE=$(git log -1 --format=%cd --date=format:%Y-%m-%d_%H%M)
    
    if [[ -n "$PKG_VERSION" && -n "$COMMIT_DATE" ]]; then
        TAG_NAME="v$PKG_VERSION-$branch_type-$COMMIT_DATE"
        echo "Creating tag for $branch_name: $TAG_NAME"
        git tag "$TAG_NAME"
        git push origin "$TAG_NAME"
    else
        echo "Failed to generate tag for $branch_name (PKG_VERSION: '$PKG_VERSION', COMMIT_DATE: '$COMMIT_DATE')"
    fi
}

# Tag develop branch
create_tag_for_branch "dev" "develop"

# Tag latest RC branch
LATEST_RC=$(git branch -r | grep -E 'v[0-9.]+-(R|r)(C|c)' | sed 's/origin\///' | sort -V | tail -1 | xargs)
if [[ -n "$LATEST_RC" ]]; then
    create_tag_for_branch "rc" "$LATEST_RC"
else
    echo "No RC branches found"
fi