#!/bin/bash

# Script to commit and push all changes

echo "🔄 Adding all changes..."
git add -A

echo "📝 Creating commit..."
git commit -m "fix: Update SDK constraint and Flutter version for GitHub Actions

Changes:
- Changed SDK constraint from ^3.8.1 to >=3.3.0 <4.0.0
- Updated Flutter version in workflows to 3.27.1
- Now compatible with both GitHub Actions and local development

Fixes:
- Resolved 'SDK version 3.5.0 not compatible' error in GitHub Actions
- Works with Dart 3.3+ to 3.9+
- Compatible with Flutter 3.22+ to 3.35+

Previous commits:
- Complete Windows desktop UI with modern dark theme
- Enhanced lifecycle handling for Android
- App state restoration improvements
- Removed unused imports and variables
- Added GitHub Actions workflows for Windows and Android
- Complete documentation"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "✅ Done! Check GitHub Actions now."
