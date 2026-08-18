#!/bin/sh
# Publishes a new OTA bundle for the native app to pick up on next
# launch: zips www/ (kept in sync with the root index.html/favicon.png
# by `npm run sync:www`), writes it to ota/bundle-<version>.zip, and
# points ota/latest.json at it with a sha256 checksum. Both files are
# plain static files in this repo, so `git push` deploys them to
# Vercel the same way as everything else — no separate hosting step.
#
# Usage: npm run ota:publish -- 1.0.1
set -e

VERSION="$1"
if [ -z "$VERSION" ]; then
  echo "Usage: npm run ota:publish -- <version>" >&2
  echo "e.g.:  npm run ota:publish -- 1.0.1" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

npm run sync:www

BUNDLE="ota/bundle-$VERSION.zip"
mkdir -p ota
rm -f "$BUNDLE"
( cd www && zip -X -r "../$BUNDLE" . -x '.*' )

CHECKSUM=$(shasum -a 256 "$BUNDLE" | cut -d' ' -f1)
BASE_URL="https://solitaire-snowy.vercel.app"

cat > ota/latest.json <<JSON
{
  "version": "$VERSION",
  "url": "$BASE_URL/$BUNDLE",
  "checksum": "$CHECKSUM"
}
JSON

echo "Published $BUNDLE"
echo "  version:  $VERSION"
echo "  checksum: $CHECKSUM"
echo ""
echo "Next: commit and push ota/ so Vercel deploys it, e.g."
echo "  git add ota/ && git commit -m \"Publish OTA update $VERSION\" && git push"
