# Release media

Privacy-reviewed presentation assets for the project README and releases.

The v1.1 RC audit confirmed that the published files contain no embedded
comment or profile metadata. Their dimensions and SHA-256 digests are recorded
in `release-media.sha256`; validation rejects any unreviewed replacement.

| File | Source |
|---|---|
| `desktop-hero.png` | Live workspace OSD over wallpaper 7, with the telemetry bar removed |
| `start-page.png` | Headless Chromium capture using `?demo=1` fictional telemetry |
| `session-menu.png` | Real menu panel isolated from a live capture and composited over project wallpaper 3 |
| `lock-screen.png` | Clean live lock-screen capture |
| `wallpaper-gallery.png` | Contact sheet generated from all seven audited wallpapers |
| `profile-switching.gif` | Illustrative MAGI, Engineering, and EVA-01 profile sequence built from project artwork and palette colors |

The original validation/capture archive is intentionally excluded from Git.
Some rejected source frames contain browser activity, media recommendations,
machine details, or development conversation text and must not be published.

Before replacing a release image, visually inspect the complete frame, remove
metadata, update `release-media.sha256`, and record why the source is safe here.

To capture the start page without exposing live telemetry, visit:

```text
http://127.0.0.1:8765/?demo=1
```
