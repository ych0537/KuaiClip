#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# ─── Config ──────────────────────────────────────────────────
REPO="ych0537/KuaiClip"

# ─── Usage ───────────────────────────────────────────────────
usage() {
    echo "Usage: $0 <version> <message>"
    echo "  version   Semver tag, e.g. v1.5.2"
    echo "  message   Short release title / commit message"
    echo ""
    echo "Example: $0 v1.5.2 'Fix clipboard paste delay'"
    exit 1
}

VERSION="${1:-}"
MESSAGE="${2:-}"

if [ -z "$VERSION" ] || [ -z "$MESSAGE" ]; then
    usage
fi

# ─── Checks ──────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
    echo "ERROR: gh (GitHub CLI) not found. Install: brew install gh"
    exit 1
fi
if ! gh auth status &>/dev/null; then
    echo "ERROR: gh not authenticated. Run: gh auth login"
    exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "→ Uncommitted changes detected — will include in release."
fi

# ─── Build check ─────────────────────────────────────────────
echo "→ Building..."
swift build || { echo "ERROR: Build failed"; exit 1; }
echo "✓ Build passes"

# ─── Commit ──────────────────────────────────────────────────
git add -A
git commit -m "$MESSAGE" || echo "(nothing to commit, continuing)"

# ─── Tag & Push ──────────────────────────────────────────────
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "! Tag $VERSION already exists, skipping tag creation"
else
    git tag "$VERSION"
fi

echo "→ Pushing to origin..."
git push origin main --tags

# ─── GitHub Release ──────────────────────────────────────────
if gh release view "$VERSION" &>/dev/null; then
    echo "! Release $VERSION already exists, updating notes..."
    gh release edit "$VERSION" --title "$VERSION" --notes "$MESSAGE"
else
    echo "→ Creating GitHub Release $VERSION..."
    gh release create "$VERSION" --title "$VERSION" --notes "$MESSAGE" --generate-notes
fi

echo ""
echo "✓ Release $VERSION published: https://github.com/$REPO/releases/tag/$VERSION"
