#!/bin/bash
# Stages a Morrowind installation as APK assets: app/embedded-game/morrowind/
set -euo pipefail

SRC="${1:?usage: stage-embedded-game.sh <morrowind install dir> [win1250|win1251|win1252]}"
ENCODING="${2:-win1252}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/app/embedded-game"
GAME="$OUT/morrowind"

[[ -f "$SRC/Morrowind.ini" && -d "$SRC/Data Files" ]] || { echo "Not a Morrowind install: $SRC" >&2; exit 1; }

mkdir -p "$GAME"
rsync -a --delete "$SRC/Data Files/" "$GAME/Data Files/"
cp "$SRC/Morrowind.ini" "$GAME/Morrowind.ini"

# Some editions keep the base-game videos next to Morrowind.exe instead of Data Files/Video.
if [[ -d "$SRC/Video" ]]; then
    mkdir -p "$GAME/Data Files/Video"
    rsync -a --ignore-existing "$SRC/Video/" "$GAME/Data Files/Video/"
fi

# size<TAB>relative path; read by EmbeddedGame.kt for the copy and its progress bar.
(cd "$GAME" && find . -type f ! -name '.*' -printf '%s\t%P\n' | sort -k2) > "$OUT/morrowind.manifest"

echo "$ENCODING" > "$OUT/morrowind.encoding"

echo "Staged $(wc -l < "$OUT/morrowind.manifest") files, $(du -sh "$GAME" | cut -f1)"
