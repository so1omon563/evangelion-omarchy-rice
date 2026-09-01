# Omarchy gallery submission draft

Target: [`omacom/omarchy-site`](https://github.com/omacom/omarchy-site)

Prepared against upstream commit `9832321e9b9cdb4f8124dda7fd33eea776ec468a`.
Do not open the pull request without the repository owner's explicit approval.

Theme source: [`so1omon563/omarchy-evangelion-theme`](https://github.com/so1omon563/omarchy-evangelion-theme)
at verified commit `c117a3ca6d2ecb07a3cd13f5a2e1e075c751b06a`.

## Submission text

> Add Evangelion, an unofficial non-commercial fan theme with an EVA-inspired
> command-center palette and seven original prompt-generated wallpapers. The
> linked repository is a declarative Omarchy theme package: no Lua, executable
> hooks, terminal launch configuration, or suite components are included.
> Wallpaper provenance, audited hashes, CC BY-NC 4.0 terms, and third-party
> trademark limitations are documented in the theme repository.

## Complete site change

Add `assets/themes/evangelion.webp`, then insert this block in
`themes/index.html` after Eldritch and before Event Horizon:

```diff
 <figure class="themes__theme">
   <a href="https://github.com/eldritch-theme/omarchy"><img src="/assets/themes/eldritch.webp" alt="Eldritch theme" loading="lazy" decoding="async"></a>
   <figcaption><a href="https://github.com/eldritch-theme/omarchy">Eldritch</a></figcaption>
 </figure>
+<figure class="themes__theme">
+  <a href="https://github.com/so1omon563/omarchy-evangelion-theme"><img src="/assets/themes/evangelion.webp" alt="Evangelion theme" loading="lazy" decoding="async"></a>
+  <figcaption><a href="https://github.com/so1omon563/omarchy-evangelion-theme">Evangelion</a></figcaption>
+</figure>
 <figure class="themes__theme">
   <a href="https://github.com/OldJobobo/omarchy-event-horizon-theme"><img src="/assets/themes/event-horizon.webp" alt="Event Horizon theme" loading="lazy" decoding="async"></a>
   <figcaption><a href="https://github.com/OldJobobo/omarchy-event-horizon-theme">Event Horizon</a></figcaption>
 </figure>
```

No other upstream files change. The binary addition is the reviewed
`evangelion.webp` in this directory.

## Preview evidence

- Source: real 1920×1080 Omarchy workspace captured on 2026-08-31
- Surfaces: sanitized shell terminal and read-only Neovim editor
- Wallpaper: active Evangelion theme background
- Excluded: cursor, notifications, browser content, personal files, host/user
  identity, live system/process/network telemetry
- Conversion: `magick source.png -strip -resize '1200>' -quality 80 evangelion.webp`
- Required output: 1200×675 WebP, below approximately 100 KB

The source capture remains outside Git because it is validation material. Its
SHA-256 and the output SHA-256 are recorded in `submission.json`.

## Owner approval checklist

- [ ] Dedicated public theme repository contents and install command approved
- [ ] `evangelion.webp` visually approved at full resolution
- [ ] Fan-project and non-commercial artwork language approved
- [ ] Exact HTML block and alphabetical position approved
- [ ] Permission explicitly given to fork and open the external pull request
