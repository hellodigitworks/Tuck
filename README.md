# Tuck

Hides the menu bar icons you are not using right now. Drag them to the left of
Tuck's line, click the chevron, and they are out of sight. Click again and they
are back. Nothing is removed and nothing is running except one small menu bar app.

How it hides: macOS lays out menu bar icons from the right, and an icon that
does not fit disappears along with everything to its left. When you hide, Tuck's
line and an invisible spacer next to it each become half a screen wide. The first
one that no longer fits takes every icon left of it out of view. Nothing is
removed. Thin them again and the icons are back.

## Use it

Open `build/Tuck.app`. Two marks appear on the right of the menu bar: a thin
line and a chevron.

- Hold ⌘ and drag any icon to the left of the line. It now hides with the rest.
- Click the chevron to show or hide them. It reads ‹ while they are hidden.
- The very first time, nothing hides until you click ›. After that Tuck starts hidden.
- They hide again on their own after 10 seconds. Change or switch that off in Preferences.
- Right-click the chevron, or click the line, for the menu: show, hide, Preferences, Quit.

**Always-hidden section.** Turn it on in Preferences and a dotted line appears.
Icons left of it stay hidden even while the others are showing. Option-click the
chevron to peek at them.

**Keyboard shortcut.** Record one in Preferences. It works from any app and
needs ⌘, ⌥ or ⌃ plus a key.

**Start at login.** A checkbox in Preferences. Move the app to `/Applications`
first so macOS can always find it.

**From a script, Raycast or Shortcuts:**

```bash
/Applications/Tuck.app/Contents/MacOS/Tuck --toggle
```

## Rebuild from source

```bash
zsh scripts/make-app.sh
```

Add `--install` to copy the finished app into `/Applications`. Tests:

```bash
zsh scripts/test.sh
```

## Folders

| Folder | What |
|---|---|
| `src/data/` | Settings, the keyboard shortcut, start at login. No screen code |
| `src/app/` | App start-up and the three menu bar marks |
| `src/ui/` | The preferences window and the shortcut recorder |
| `scripts/` | Build script, test script and icon generator |
| `icons/` | Generated app icon |
| `tests/` | Tests for the settings and shortcut logic |
| `build/` | The finished app (generated, not committed) |
