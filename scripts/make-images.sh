#!/bin/zsh
# Makes every picture in docs/images and site/images: the window, the README hero, the
# before and after menu bar, the social card, the link preview, the lab shot and the
# landing page's icons. Run: zsh scripts/make-images.sh
#
# Needs Tuck installed in /Applications (zsh scripts/make-app.sh --install). It relaunches
# Tuck so the little demo in the window is caught in its opening "showing" state.
set -e
cd "$(dirname "$0")/.."
mkdir -p docs/images

# 1. Photograph the real window.
pkill -x Tuck 2>/dev/null || true
sleep 1
open /Applications/Tuck.app
sleep 1.5
open /Applications/Tuck.app   # opening it again brings the window up
sleep 1

FINDER="$(mktemp -t tuck-window).swift"
cat > "$FINDER" <<'SWIFT'
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w["kCGWindowOwnerName"] as? String) == "Tuck" {
    let bounds = w["kCGWindowBounds"] as! [String: Any]
    if (bounds["Width"] as! Int) > 300 { print(w["kCGWindowNumber"] as! Int); break }
}
SWIFT
WID="$(swift "$FINDER" 2>/dev/null)"
rm -f "$FINDER"
if [ -z "$WID" ]; then
  echo "Tuck's window is not on screen. Is it installed in /Applications?" >&2
  exit 1
fi
screencapture -l "$WID" -o -x docs/images/window.png
echo "  window.png"

# 2. Draw the rest around it, in the fonts the app ships.
swift scripts/make-images.swift
