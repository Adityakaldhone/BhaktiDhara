#!/usr/bin/env bash
# Builds the Google Ads App-campaign HTML5 bundles from src/.
# Output: dist/bhaktidhara_320x480.zip (portrait) and dist/bhaktidhara_480x320.zip (landscape).
set -euo pipefail
cd "$(dirname "$0")"

rm -rf dist && mkdir -p dist

build() {
  local name=$1 size=$2 orientation=$3
  local dir="dist/$name"
  mkdir -p "$dir"
  cp src/*.jpg src/*.png src/*.woff2 "$dir/"
  sed -e "s/__AD_SIZE__/$size/" -e "s/__AD_ORIENTATION__/$orientation/" src/index.html > "$dir/index.html"
  (cd "$dir" && zip -qX "../$name.zip" ./*)
  echo "$name.zip  $(du -h "dist/$name.zip" | cut -f1)"
}

build bhaktidhara_320x480 "width=320,height=480" portrait
build bhaktidhara_480x320 "width=480,height=320" landscape
