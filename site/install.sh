#!/bin/sh
# Installs Tuck with one line in Terminal:
#
#   curl -fsSL https://tuck.hellodigitworks.com/install.sh | sh
#
# Downloads the latest release from GitHub, puts Tuck.app in /Applications and opens it.
# macOS only tags files saved from a browser as downloads, and curl is not a browser, so
# the "could not verify" warning never appears. Nothing else is touched: no login item,
# no settings, nothing outside the app itself.
#
# Two knobs, both optional, for trying the script somewhere harmless:
#   TUCK_DIR=/some/folder   install there instead of /Applications
#   TUCK_OPEN=0             do not open Tuck at the end
set -eu

ZIP_URL="https://github.com/hellodigitworks/Tuck/releases/latest/download/Tuck.zip"

say() { printf '%s\n' "$*"; }
fail() { say "Tuck: $*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "this is a Mac app."
[ "$(uname -m)" = "arm64" ] || fail "needs a Mac with Apple silicon."
major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$major" -ge 13 ] 2>/dev/null || fail "needs macOS 13 or later."

dest="${TUCK_DIR:-/Applications}"
if [ ! -d "$dest" ] || [ ! -w "$dest" ]; then
  # /Applications is writable by any admin account. When it is not, the user's own
  # Applications folder does the same job; macOS treats both alike.
  dest="$HOME/Applications"
  mkdir -p "$dest"
fi

tmp="$(mktemp -d -t tuck)"
trap 'rm -rf "$tmp"' EXIT

say "Downloading Tuck…"
curl -fsSL -o "$tmp/Tuck.zip" "$ZIP_URL" || fail "could not download from GitHub. Check the connection and try again."
ditto -x -k "$tmp/Tuck.zip" "$tmp" || fail "the download did not unzip."
[ -d "$tmp/Tuck.app" ] || fail "the download had no Tuck.app inside."
# curl leaves no quarantine tag. If one is ever there anyway, drop it.
xattr -dr com.apple.quarantine "$tmp/Tuck.app" 2>/dev/null || true

if pgrep -x Tuck >/dev/null 2>&1; then
  say "Quitting the Tuck that is running…"
  pkill -x Tuck || true
  sleep 1
fi

rm -rf "$dest/Tuck.app"
ditto "$tmp/Tuck.app" "$dest/Tuck.app" || fail "could not copy Tuck into $dest."
say "Tuck is in $dest."

if [ "${TUCK_OPEN:-1}" != "0" ]; then
  open "$dest/Tuck.app"
  say "Look for its mark in the menu bar."
fi
