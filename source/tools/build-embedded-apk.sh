#!/bin/bash
# Builds the signed release APK with bundled Morrowind data. Needs only Docker, curl, unzip and rsync on Linux/WSL.
# usage: tools/build-embedded-apk.sh "<Morrowind install dir>" [win1250|win1251|win1252]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${1:?usage: build-embedded-apk.sh <Morrowind install dir> [encoding]}"
ENCODING="${2:-win1251}"
SDK="${ANDROID_SDK_DIR:-$HOME/Android/sdk}"
GRADLE_HOME="${GRADLE_HOME_DIR:-$HOME/.cache/openmw-android-gradle}"
IMAGE="omw-android-build"

echo "==> Docker image $IMAGE"
docker build -q -t "$IMAGE" "$ROOT/docker" >/dev/null

# Create mount points as the current user; Docker would create them owned by root.
mkdir -p "$SDK/cmdline-tools" "$GRADLE_HOME"

in_docker() {
    docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp/h -e GRADLE_USER_HOME=/gradle-home \
        -v "$ROOT":/src -v "$SDK":/sdk -v "$GRADLE_HOME":/gradle-home -w /src "$IMAGE" \
        bash -c "mkdir -p /tmp/h && $1"
}

if [[ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]]; then
    echo "==> Android command-line tools"
    TMP="$(mktemp -d)"
    curl -fSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o "$TMP/clt.zip"
    unzip -q "$TMP/clt.zip" -d "$TMP"
    rm -rf "$SDK/cmdline-tools/latest"
    mv "$TMP/cmdline-tools" "$SDK/cmdline-tools/latest"
    rm -rf "$TMP"
fi

echo "==> Android SDK packages"
in_docker 'S=/sdk/cmdline-tools/latest/bin/sdkmanager; yes | $S --licenses >/dev/null 2>&1; $S "platforms;android-35" "build-tools;35.0.0" "build-tools;34.0.0" "platform-tools" "ndk;26.1.10909125" >/dev/null'
echo "sdk.dir=/sdk" > "$ROOT/local.properties"

"$ROOT/tools/fetch-native-payload.sh"

echo "==> Staging game data"
"$ROOT/tools/stage-embedded-game.sh" "$GAME_DIR" "$ENCODING"

echo "==> Gradle assembleMainlineRelease"
in_docker './gradlew --no-daemon :app:assembleMainlineRelease'

ls -la "$ROOT/app/build/outputs/apk/mainline/release/"
