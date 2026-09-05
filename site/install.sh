#!/bin/sh
# Installs Duck with one line in Terminal:
#
#   curl -fsSL https://duck.hellodigitworks.com/install.sh | sh
#
# Downloads the latest release from GitHub, puts Duck.app in /Applications and opens it.
# macOS only tags files saved from a browser as downloads, and curl is not a browser, so
# the "could not verify" warning never appears. Nothing else is touched: no login item,
# no settings, nothing outside the app itself.
#
# Two knobs, both optional, for trying the script somewhere harmless:
#   DUCK_DIR=/some/folder   install there instead of /Applications
#   DUCK_OPEN=0             do not open Duck at the end
set -eu

ZIP_URL="https://github.com/hellodigitworks/Duck/releases/latest/download/Duck.zip"

say() { printf '%s\n' "$*"; }
fail() { say "Duck: $*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "this is a Mac app."
[ "$(uname -m)" = "arm64" ] || fail "needs a Mac with Apple silicon."
major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$major" -ge 13 ] 2>/dev/null || fail "needs macOS 13 or later."

dest="${DUCK_DIR:-/Applications}"
if [ ! -d "$dest" ] || [ ! -w "$dest" ]; then
  # /Applications is writable by any admin account. When it is not, the user's own
  # Applications folder does the same job; macOS treats both alike.
  dest="$HOME/Applications"
  mkdir -p "$dest"
fi

tmp="$(mktemp -d -t duck)"
trap 'rm -rf "$tmp"' EXIT

say "Downloading Duck…"
curl -fsSL -o "$tmp/Duck.zip" "$ZIP_URL" || fail "could not download from GitHub. Check the connection and try again."
ditto -x -k "$tmp/Duck.zip" "$tmp" || fail "the download did not unzip."
[ -d "$tmp/Duck.app" ] || fail "the download had no Duck.app inside."
# curl leaves no quarantine tag. If one is ever there anyway, drop it.
xattr -dr com.apple.quarantine "$tmp/Duck.app" 2>/dev/null || true

if pgrep -x Duck >/dev/null 2>&1; then
  say "Quitting the Duck that is running…"
  pkill -x Duck || true
  sleep 1
fi

rm -rf "$dest/Duck.app"
ditto "$tmp/Duck.app" "$dest/Duck.app" || fail "could not copy Duck into $dest."
say "Duck is in $dest."

if [ "${DUCK_OPEN:-1}" != "0" ]; then
  open "$dest/Duck.app"
  say "Look for its mark in the menu bar."
fi
