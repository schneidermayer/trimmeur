#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="trimmeur"

usage() {
  cat <<EOF
Usage: scripts/release_github.sh <version>

Creates a signed and notarized production build, creates and pushes git tag
v<version>, and publishes the precompiled zip on GitHub Releases.

Example:
  scripts/release_github.sh 1.0
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

VERSION="$1"
TAG="v${VERSION}"
ZIP_PATH="${ROOT_DIR}/dist/prod/${PRODUCT_NAME}-${VERSION}.zip"
CURRENT_BRANCH="$(git -C "${ROOT_DIR}" branch --show-current)"

[[ -n "${CURRENT_BRANCH}" ]] || die "must be on a branch"

require_command git
require_command gh

if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
  die "working tree must be clean before release"
fi

git -C "${ROOT_DIR}" fetch --tags origin

if git -C "${ROOT_DIR}" rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  die "tag already exists locally: ${TAG}"
fi

if git -C "${ROOT_DIR}" ls-remote --exit-code --tags origin "refs/tags/${TAG}" >/dev/null 2>&1; then
  die "tag already exists on origin: ${TAG}"
fi

gh auth status >/dev/null

echo "Building production release ${VERSION}..."
VERSION="${VERSION}" "${ROOT_DIR}/scripts/build.sh" prod

[[ -f "${ZIP_PATH}" ]] || die "expected release zip was not created: ${ZIP_PATH}"

echo "Creating git tag ${TAG}..."
git -C "${ROOT_DIR}" tag -a "${TAG}" -m "Release ${VERSION}"

echo "Pushing branch and tag..."
git -C "${ROOT_DIR}" push origin "${CURRENT_BRANCH}"
git -C "${ROOT_DIR}" push origin "${TAG}"

echo "Creating GitHub release ${TAG}..."
gh release create "${TAG}" \
  "${ZIP_PATH}" \
  --title "Trimmeur ${VERSION}" \
  --notes "Precompiled macOS app bundle for Trimmeur ${VERSION}."

echo "GitHub release created: ${TAG}"
