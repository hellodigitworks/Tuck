# Duck health

Status: AMBER. First record, and nothing is wrong with the app: everything live answers, the page is internally consistent and the five undeployed commits are a pending deploy, not a fault. The AMBER is about us, not it. This app has been live on its own domain since 5 Sep and was in no run until tonight, because it was in no registry, and its tier is still Code Review's reading rather than his decision.
Checked: 2026-09-06 23:58 IST, baseline

## Live
| Address | Result | Note |
|---|---|---|
| https://duck.hellodigitworks.com/ | 200, 5.9 KB, html | title Duck, og:image 200 at 180 KB, manifest 200 with icons, apple-touch-icon 200, favicon.svg and favicon-32 200. Absolute URLs all name the served host. 0 console errors, 0 failed requests, desktop and phone |
| https://tuck-2nv.pages.dev/ | 200, 5.9 KB, html | the project address, identical. The project kept its first name, only the domain changed |
| https://duck.hellodigitworks.com/install.sh | 200, 2,161 B, x-sh | the Install button copies a one-line command that fetches this. It serves the real script, not the fallback page |
| https://github.com/hellodigitworks/Duck/releases/latest/download/Duck.zip | 200, 410 KB, octet-stream | the download the readme points at. Answers, and it is GitHub's to serve, not ours |
| https://duck.hellodigitworks.com/fonts/fraunces.woff2 | 200, 65,912 B, woff2 | the live page's display font. Consistent with the live CSS |
| https://duck.hellodigitworks.com/wrangler.toml | 200, 550 B, toml | published because the deploy root is the site folder. It holds a project name, an output path and a date, no id and no secret, and the file explains itself. Same shape as lab's, recorded rather than flagged |

## Deploy state

- Local ahead by 5 commits since the last deploy. Production is `0754ae63`, commit `de3e7f6`, 22 hours old, and it is self-consistent: the live page asks for the old fonts and the old icon versions, and every one of them answers 200. Nothing is half-shipped.
- Last commit: 2026-09-06, 2783cba The duck is a black print now, and everything that shows it is remade
- Last deploy: 22 hours before this run, commit `de3e7f6`, read from `wrangler pages deployment list --project-name tuck`
- Uncommitted: none. Local main is level with origin/main
- Deploys by: `npx wrangler pages deploy site --project-name tuck --branch main`, or the same line with `.` from inside site/, which is what the folder's own wrangler.toml documents

## Open issues
| # | Sev | What | Where | Since | Proposed fix | Decision |
|---|---|---|---|---|---|---|
| 1 | AMBER | The app was not in the registry, so from the day it went live nothing checked it. It was found tonight only because it appeared as a row on lab. Its tier here is Code Review's reading, not a decision he has made | Code Review/apps.json | 2026-09-05 | Added to the registry tonight as tier 1, so it is in the daily from now on. He confirms or changes the tier | needs Swayam |
| 2 | low | Five commits are built and not deployed: a new hand-drawn mark, the app icon made from it, a display typeface swap, and every icon and share image regenerated at `?v=3` and `?v=4`. Live still serves the previous set at `?v=2` | site/, icons/ | 2026-09-06 | A deploy, when he wants it. Never Code Review's to run for a change this size | needs Swayam |

## Reviewed changes
- 2026-09-06: five commits, none deployed. `8a47b50` draws the mark by hand and builds the app icon from it. `fa84d56` adds a Show in Dock preference, off by default. `faa4cd7` swaps the display typeface into the window title, the page headline and the pictures. `0c5ccc4` removes the old typeface and its licence file from both the app and the site, and cuts the font builder down to one family. `2783cba` remakes every icon, favicon and share image from the new mark and bumps the page to `?v=3` and `?v=4`, with the service worker bumped alongside. ok as a set: the version stamps and the service worker moved together, the removed font is gone from the CSS as well as the folder, and the page in the folder is consistent with the files in the folder. The live site is consistent with itself at the older version, so nothing is broken while the deploy waits
- 2026-09-06: baseline read of the folder. No secret in a tracked file, no real client or person name, no console.log in the shipping page, every internal href in the page resolves to a file that exists both in the folder and live at the version that page asks for. The download link points at the GitHub release rather than anything hosted here

## Showcases waiting
| Branch | Preview | Shots | What to test | Asked |
|---|---|---|---|---|

## Fixed by Code Review
| Date | What | Commit | Pushed | Deployed | Verified live |
|---|---|---|---|---|---|
