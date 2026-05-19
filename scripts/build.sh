#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="trimmeur"
TARGET_NAME="TrimmeurMacOS"
APP_BUNDLE_NAME="Trimmeur"
BUNDLE_ID="${BUNDLE_ID:-com.inndevs.trimmeur}"
TEAM_ID="${TEAM_ID:-AW7ZNT442J}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Hannes Schneidermayer (AW7ZNT442J)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-emoji-picker-macos-notary}"
BUILD_ARCHS="${BUILD_ARCHS:-}"

usage() {
  cat <<EOF
Usage: scripts/build.sh [debug|prod]

Build types:
  debug  Runs tests, builds a Debug app for the host architecture, and ad-hoc signs it.
  prod   Runs tests, builds a universal Release app, Developer ID signs it, zips it,
         notarizes it, staples it, and re-zips the stapled app.

Environment:
  VERSION             CFBundleShortVersionString (default: git-derived version)
  BUILD_NUMBER        CFBundleVersion (default: timestamp)
  BUNDLE_ID           App bundle id (default: com.inndevs.trimmeur)
  TEAM_ID             Apple team id for notarization
  CODESIGN_IDENTITY   Developer ID identity for prod; debug always uses ad-hoc signing
  NOTARY_PROFILE      notarytool keychain profile
  BUILD_ARCHS         Optional arch list, for example "arm64 x86_64"
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

derive_version() {
  local fallback_version="0.1.0"
  local describe_output=""

  if ! command -v git >/dev/null 2>&1; then
    echo "${fallback_version}"
    return
  fi

  if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "${fallback_version}"
    return
  fi

  describe_output="$(git -C "${ROOT_DIR}" describe --tags --long --dirty --match 'v*' 2>/dev/null || true)"
  if [[ "${describe_output}" =~ ^v(.+)-([0-9]+)-g[0-9a-f]+(-dirty)?$ ]]; then
    local tag_version="${BASH_REMATCH[1]}"
    local commit_count="${BASH_REMATCH[2]}"
    local dirty_suffix="${BASH_REMATCH[3]}"

    if [[ "${commit_count}" == "0" ]]; then
      echo "${tag_version}${dirty_suffix}"
    else
      echo "${tag_version}-${commit_count}${dirty_suffix}"
    fi
    return
  fi

  describe_output="$(git -C "${ROOT_DIR}" describe --tags --always --dirty 2>/dev/null || true)"
  if [[ -n "${describe_output}" ]]; then
    echo "${describe_output#v}"
    return
  fi

  echo "${fallback_version}"
}

zip_app() {
  local app_dir="$1"
  local zip_path="$2"
  rm -f "${zip_path}"
  COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc "${app_dir}" "${zip_path}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

BUILD_TYPE="${1:-debug}"
case "${BUILD_TYPE}" in
  debug)
    CONFIG="debug"
    SIGN_IDENTITY="-"
    SHOULD_NOTARIZE="0"
    ;;
  prod)
    CONFIG="release"
    SIGN_IDENTITY="${CODESIGN_IDENTITY}"
    SHOULD_NOTARIZE="1"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

require_command swift
require_command codesign
require_command ditto
if [[ "${SHOULD_NOTARIZE}" == "1" ]]; then
  require_command xcrun
  require_command spctl
fi

VERSION="${VERSION:-$(derive_version)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"
DIST_DIR="${ROOT_DIR}/dist/${BUILD_TYPE}"
APP_DIR="${DIST_DIR}/${APP_BUNDLE_NAME}.app"
BIN_DIR=""
BIN_PATH=""

echo "[1/5] Running tests"
"${ROOT_DIR}/scripts/test.sh"

echo "[2/5] Generating app icon"
"${ROOT_DIR}/scripts/generate_icon.sh"

cd "${ROOT_DIR}"

SWIFT_BUILD_ARGS=()
if [[ -n "${BUILD_ARCHS}" ]]; then
  for arch in ${BUILD_ARCHS}; do
    SWIFT_BUILD_ARGS+=(--arch "${arch}")
  done
elif [[ "${BUILD_TYPE}" == "prod" ]]; then
  SWIFT_BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi

if [[ ${#SWIFT_BUILD_ARGS[@]} -gt 0 ]]; then
  echo "Using architectures: ${SWIFT_BUILD_ARGS[*]}"
fi

echo "[3/5] Building (${CONFIG})"
swift build -c "${CONFIG}" "${SWIFT_BUILD_ARGS[@]}"
BIN_DIR="$(swift build -c "${CONFIG}" "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"
BIN_PATH="${BIN_DIR}/${PRODUCT_NAME}"
[[ -x "${BIN_PATH}" ]] || die "missing binary at ${BIN_PATH}"

if command -v lipo >/dev/null 2>&1; then
  lipo -info "${BIN_PATH}" || true
fi

echo "[4/5] Packaging .app"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/${PRODUCT_NAME}"

for bundle in "${BIN_DIR}"/*.bundle; do
  if [[ -d "${bundle}" ]]; then
    cp -R "${bundle}" "${APP_DIR}/Contents/Resources/"
  fi
done

cp "${ROOT_DIR}/Sources/${TARGET_NAME}/Resources/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"

cat > "${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${PRODUCT_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_BUNDLE_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_BUNDLE_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

chmod +x "${APP_DIR}/Contents/MacOS/${PRODUCT_NAME}"

echo "[5/5] Signing"
if [[ "${BUILD_TYPE}" == "debug" ]]; then
  codesign --force --sign - \
    -r="designated => identifier \"${BUNDLE_ID}\"" \
    "${APP_DIR}"
else
  [[ -n "${SIGN_IDENTITY}" && "${SIGN_IDENTITY}" != "-" ]] || die "prod build requires CODESIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "${SIGN_IDENTITY}" "${APP_DIR}"
fi
codesign --verify --deep --strict "${APP_DIR}"

if [[ "${SHOULD_NOTARIZE}" == "1" ]]; then
  ZIP_PATH="${DIST_DIR}/${PRODUCT_NAME}-${VERSION}.zip"
  echo "Creating notarization zip: ${ZIP_PATH}"
  zip_app "${APP_DIR}" "${ZIP_PATH}"

  echo "Submitting to Apple notarization using profile: ${NOTARY_PROFILE}"
  xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait

  echo "Stapling notarization ticket"
  xcrun stapler staple "${APP_DIR}"
  xcrun stapler validate "${APP_DIR}"
  spctl --assess --type execute --verbose=4 "${APP_DIR}"

  echo "Re-zipping stapled app"
  zip_app "${APP_DIR}" "${ZIP_PATH}"
  echo "Production artifact: ${ZIP_PATH}"
fi

echo "Built: ${APP_DIR}"
echo "Launch with: open \"${APP_DIR}\""
