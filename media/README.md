# Release media

Privacy-reviewed presentation assets for the project README and releases.

| File | Source |
|---|---|
| `desktop-hero.png` | Clean live workspace OSD capture |
| `start-page.png` | Headless Chromium capture using `?demo=1` fictional telemetry |
| `session-menu.png` | Real menu panel isolated from a live capture and composited over project wallpaper 3 |
| `lock-screen.png` | Clean live lock-screen capture |
| `wallpaper-gallery.png` | Contact sheet generated from all seven audited wallpapers |
| `profile-switching.gif` | Three clean live captures of MAGI, Engineering, and EVA-01 terminal profiles |

The original validation/capture archive is intentionally excluded from Git.
Some rejected source frames contain browser activity, media recommendations,
machine details, or development conversation text and must not be published.

To capture the start page without exposing live telemetry, visit:

```text
http://127.0.0.1:8765/?demo=1
```
