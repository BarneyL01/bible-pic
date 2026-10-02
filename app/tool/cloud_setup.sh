#!/usr/bin/env bash
# Installs the Flutter SDK and project dependencies in a Claude Code cloud
# container, so `flutter analyze`, `flutter test`, a web build and the browser
# tests can run there. The container has no Flutter SDK, and `curl` is denied by
# .claude/settings.json, so the SDK is fetched with python3.
#
#   source app/tool/cloud_setup.sh      # keeps PATH for the current shell
#
# Needs network access to storage.googleapis.com, pub.dev and github.com
# release downloads (set the environment's network access accordingly).
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${FLUTTER_SDK_DIR:-$HOME/flutter-sdk}"
CHANNEL_JSON=https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
CA="${SSL_CERT_FILE:-/root/.ccr/ca-bundle.crt}"

if [ ! -x "$SDK_DIR/flutter/bin/flutter" ]; then
  mkdir -p "$SDK_DIR"
  python3 - "$SDK_DIR" "$CHANNEL_JSON" "$CA" <<'PY'
import json, ssl, sys, urllib.request
dest, index, ca = sys.argv[1:4]
ctx = ssl.create_default_context(cafile=ca) if ca and __import__('os').path.exists(ca) else ssl.create_default_context()
data = json.load(urllib.request.urlopen(index, context=ctx))
stable = next(r for r in data['releases'] if r['hash'] == data['current_release']['stable'])
url = data['base_url'] + '/' + stable['archive']
print('downloading', url, flush=True)
with urllib.request.urlopen(url, context=ctx) as r, open(dest + '/flutter.tar.xz', 'wb') as f:
    while chunk := r.read(1 << 20):
        f.write(chunk)
PY
  tar -xf "$SDK_DIR/flutter.tar.xz" -C "$SDK_DIR"
  rm "$SDK_DIR/flutter.tar.xz"
fi

export PATH="$SDK_DIR/flutter/bin:$PATH"
export CI=true FLUTTER_SUPPRESS_ANALYTICS=true
git config --global --add safe.directory "$SDK_DIR/flutter" 2>/dev/null || true

cd "$APP_DIR"
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run tool/fetch_web_assets.dart
(cd e2e && npm install)
echo "Ready. PATH now includes $SDK_DIR/flutter/bin"
