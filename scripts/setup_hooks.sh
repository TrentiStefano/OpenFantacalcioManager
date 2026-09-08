#!/usr/bin/env sh
echo "Configuring Git hooks path to .githooks..."
git config core.hooksPath .githooks

if [ -d ".git/hooks" ]; then
  cp -f .githooks/* .git/hooks/ 2>/dev/null || true
  chmod +x .git/hooks/* .githooks/* 2>/dev/null || true
fi

echo "✅ Git hooks installed and configured successfully!"
echo "Commit messages will now be validated against Conventional Commits."
echo "Semantic versioning tool available at: dart run tool/bump_version.dart"
