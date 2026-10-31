#!/bin/bash
# Installs the prebuilt OpenMW 0.51.0-14 native payload: arm64 libraries, engine resources, OMWFX shaders.
# verifyOpenMwPayload in app/build.gradle only accepts this exact libopenmw.so.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app/src/main"

URL="${PAYLOAD_URL:-https://github.com/des1roer/OpenMW-Android/releases/download/native-payload-0.51.0-14/openmw-native-payload-0.51.0-14.zip}"
ZIP_SHA256="6a1692b9f4cc4640277e3ea52852010f122c75d4a4ba40724164cbf1ca1bdc05"
LIBOPENMW_SHA256="a99f89d2e8de0f652de219af9acd29db48db10f55f0026cc7a911c426a7efdc0"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading $URL"
curl -fSL --retry 3 "$URL" -o "$TMP/payload.zip"
echo "$ZIP_SHA256  $TMP/payload.zip" | sha256sum -c -

unzip -q "$TMP/payload.zip" -d "$TMP/payload"

rm -rf "$APP/jniLibs/arm64-v8a" "$APP/assets/libopenmw" "$APP/assets/android_omwfx"
mkdir -p "$APP/jniLibs" "$APP/assets"
cp -r "$TMP/payload/jniLibs/arm64-v8a" "$APP/jniLibs/"
cp -r "$TMP/payload/assets/libopenmw" "$TMP/payload/assets/android_omwfx" "$APP/assets/"

echo "$LIBOPENMW_SHA256  $APP/jniLibs/arm64-v8a/libopenmw.so" | sha256sum -c -
echo "==> Native payload installed"
