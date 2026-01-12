#!/bin/bash
# Increment build number in pubspec.yaml
# Called by pre-commit hook

set -e

PUBSPEC="pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    echo "Error: $PUBSPEC not found"
    exit 1
fi

# Extract current version line (format: version: X.Y.Z+BUILD)
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not find version in $PUBSPEC"
    exit 1
fi

# Parse version and build number
VERSION_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# If no build number, start from 1
if [ "$BUILD_NUMBER" = "$VERSION_PART" ]; then
    BUILD_NUMBER=0
fi

# Increment build number
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION="${VERSION_PART}+${NEW_BUILD}"

echo "Version: $CURRENT_VERSION -> $NEW_VERSION"

# Update pubspec.yaml (compatible with both BSD and GNU sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD sed)
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
else
    # Linux/Git Bash (GNU sed)
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
fi

# Add updated pubspec.yaml to the commit
git add "$PUBSPEC"

echo "✓ Version incremented to $NEW_VERSION"

