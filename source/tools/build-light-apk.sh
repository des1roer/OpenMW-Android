#!/bin/bash
# Builds the signed release APK WITHOUT bundled game data: the launcher asks the player
# to pick their own Morrowind folder, like the upstream Andiweli/OpenMW-Android release.
# usage: tools/build-light-apk.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# No embedded-game/ staged: assembleMainlineRelease then packages without any game data.
rm -rf "$ROOT/app/embedded-game"

echo "==> Gradle assembleMainlineRelease (light, no game data)"
in_docker './gradlew --no-daemon :app:assembleMainlineRelease'

ls -la "$ROOT/app/build/outputs/apk/mainline/release/"
