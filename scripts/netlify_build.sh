#!/usr/bin/env bash
set -euo pipefail

flutter_version="3.35.7"
flutter_root="${HOME}/.cache/flutter-${flutter_version}"

if [[ ! -x "${flutter_root}/bin/flutter" ]]; then
  mkdir -p "${flutter_root}"
  curl --fail --location --silent --show-error \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_version}-stable.tar.xz" \
    | tar -xJ --strip-components=1 -C "${flutter_root}"
fi

export PATH="${flutter_root}/bin:${PATH}"
: "${FIREBASE_WEB_API_KEY:?Set FIREBASE_WEB_API_KEY in Netlify build environment variables}"

flutter pub get
flutter build web --release \
  --dart-define="FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY}" \
  --dart-define="FIREBASE_WEB_APP_ID=1:100221373274:web:d151778a6250e880f08163" \
  --dart-define="FIREBASE_AUTH_DOMAIN=srit-skolaro.firebaseapp.com" \
  --dart-define="GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-}" \
  --dart-define="GOOGLE_SERVER_CLIENT_ID=${GOOGLE_SERVER_CLIENT_ID:-}" \
  --dart-define="FIREBASE_VAPID_KEY=${FIREBASE_VAPID_KEY:-}"
