#!/bin/bash
# Setup git hooks for the project
# Run this once after cloning the repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Setting up git hooks..."

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook: increment version number

# Get the repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Only increment if pubspec.yaml is being committed or other source files changed
# Skip if only non-code files are being committed (like README, etc.)
STAGED_FILES=$(git diff --cached --name-only)

# Check if any meaningful files are staged (not just version bump)
if echo "$STAGED_FILES" | grep -qE '\.(dart|yaml|swift|kt|java|gradle|xcconfig)$|^lib/|^android/|^ios/|^\.github/'; then
    # Run the increment script
    cd "$REPO_ROOT"
    bash scripts/increment-version.sh
fi

exit 0
EOF

# Make hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✓ Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will automatically increment the build number"
echo "in pubspec.yaml before each commit."
echo ""
echo "To skip version increment for a specific commit, use:"
echo "  git commit --no-verify -m 'your message'"

