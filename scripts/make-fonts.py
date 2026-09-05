#!/usr/bin/env python3
"""Builds the fonts Tuck ships, from the two open-licence variable fonts.

Run: python3 scripts/make-fonts.py   (needs: pip3 install fonttools brotli)

Sources come from Google's fonts repo and land in fonts/source/, which is not committed.
What is committed is what this writes:

  fonts/           static TrueType instances the app bundles, Latin only
  site/fonts/      woff2 for the landing page, Latin only, weight kept variable where useful

Fraunces (undercasetype) and Inter (rsms) are both SIL Open Font Licence, which allows
exactly this: bundling, subsetting and redistribution, with the licence text alongside.
"""
import pathlib
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "fonts" / "source"
APP = ROOT / "fonts"
WEB = ROOT / "site" / "fonts"
SOURCE.mkdir(parents=True, exist_ok=True)
WEB.mkdir(parents=True, exist_ok=True)

BASE = "https://github.com/google/fonts/raw/main/ofl"
SOURCES = {
    "Fraunces.ttf": f"{BASE}/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf",
    "Fraunces-Italic.ttf": f"{BASE}/fraunces/Fraunces-Italic%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf",
    "Inter.ttf": f"{BASE}/inter/Inter%5Bopsz%2Cwght%5D.ttf",
    "OFL-Fraunces.txt": f"{BASE}/fraunces/OFL.txt",
    "OFL-Inter.txt": f"{BASE}/inter/OFL.txt",
}

# Latin, plus the keyboard and mark symbols the window shows.
UNICODES = subset.parse_unicodes(
    "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,"
    "U+20AC,U+2122,U+2190-2199,U+21A9,U+21DE-21DF,U+21E5,U+21E7,U+2212,U+2215,U+2303,U+2318,"
    "U+2325,U+2326,U+232B,U+238B,U+2715,U+FEFF,U+FFFD"
)


def fetch():
    for name, url in SOURCES.items():
        target = SOURCE / name
        if not target.exists():
            print(f"  fetching {name}")
            urllib.request.urlretrieve(url, target)


def build(source, axes, family, style, postscript, out, flavor=None):
    font = TTFont(SOURCE / source)
    font = instancer.instantiateVariableFont(font, axes, inplace=False, updateFontNames=False)

    names = font["name"]
    for nid in (16, 17):
        names.removeNames(nameID=nid)
    for nid, value in {1: family, 2: style, 3: f"{family} {style}", 4: f"{family} {style}", 6: postscript}.items():
        names.setName(value, nid, 3, 1, 0x409)
        names.setName(value, nid, 1, 0, 0)

    # A font that stays variable keeps its gvar table, and fontTools trips over a
    # missing .notdef entry there while subsetting. Give it an empty one.
    if "gvar" in font:
        variations = font["gvar"].variations
        for glyph in font.getGlyphOrder():
            if glyph not in variations:
                variations[glyph] = []

    options = subset.Options()
    options.flavor = flavor
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    cutter = subset.Subsetter(options)
    cutter.populate(unicodes=UNICODES)
    cutter.subset(font)

    font.save(out)
    print(f"  {out.relative_to(ROOT)}  {out.stat().st_size // 1024} KB")


fetch()

# The app: one static file per face. Fraunces sits at optical size 48, a little softer
# than default and without the wonky glyphs. Inter at text size, regular and medium.
build("Fraunces.ttf", {"wght": 400, "opsz": 48, "SOFT": 50, "WONK": 0},
      "Fraunces", "Regular", "Fraunces-Regular", APP / "Fraunces-Regular.ttf")
build("Fraunces-Italic.ttf", {"wght": 400, "opsz": 48, "SOFT": 50, "WONK": 0},
      "Fraunces", "Italic", "Fraunces-Italic", APP / "Fraunces-Italic.ttf")
build("Inter.ttf", {"wght": 400, "opsz": 14}, "Inter", "Regular", "Inter-Regular", APP / "Inter-Regular.ttf")
build("Inter.ttf", {"wght": 500, "opsz": 14}, "Inter", "Medium", "Inter-Medium", APP / "Inter-Medium.ttf")

# The page: Fraunces keeps its optical size axis so headlines get the high-contrast cut,
# Inter keeps a weight range so one file covers body and labels.
build("Fraunces.ttf", {"wght": 400, "SOFT": 50, "WONK": 0},
      "Fraunces", "Regular", "Fraunces-Regular", WEB / "fraunces.woff2", flavor="woff2")
build("Fraunces-Italic.ttf", {"wght": 400, "SOFT": 50, "WONK": 0},
      "Fraunces", "Italic", "Fraunces-Italic", WEB / "fraunces-italic.woff2", flavor="woff2")
build("Inter.ttf", {"wght": (400, 700), "opsz": 14}, "Inter", "Regular", "Inter-Regular", WEB / "inter.woff2", flavor="woff2")

for licence in ("OFL-Fraunces.txt", "OFL-Inter.txt"):
    (APP / licence).write_bytes((SOURCE / licence).read_bytes())
    (WEB / licence).write_bytes((SOURCE / licence).read_bytes())
print("  licences copied")
