Write-Host "Configuring Git hooks path to .githooks..." -ForegroundColor Cyan
git config core.hooksPath .githooks

# Also copy to .git/hooks as fallback
if (Test-Path ".git/hooks") {
    Copy-Item -Force ".githooks/*" ".git/hooks/"
}

Write-Host "✅ Git hooks installed and configured successfully!" -ForegroundColor Green
Write-Host "Commit messages will now be validated against Conventional Commits." -ForegroundColor Green
Write-Host "Semantic versioning tool available at: dart run tool/bump_version.dart" -ForegroundColor Green
