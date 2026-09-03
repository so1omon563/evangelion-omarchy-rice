# Guided suite updates

`magi-suite-update` updates Evangelion Omarchy Rice itself. It is intentionally
separate from `magi-update run`, which wraps the authoritative `omarchy update`
system operation.

## Channels and trust

`stable` is the default and resolves only final semantic-version tags.
`preview` resolves prerelease tags. `development` follows the exact commit at
the remote `main` head. Preview and Development require `--accept-risk`; a
channel change never downloads or applies an update.

```bash
magi-suite-update channel
magi-suite-update channel stable
magi-suite-update channel preview --accept-risk
magi-suite-update channel development --accept-risk
```

The check result displays the immutable commit and its evidence: branch or tag,
annotated/lightweight tag type when available, signature result, and published
release-gate presence. An unsigned or locally untrusted tag is reported as
such rather than presented as verified. The updater does not silently switch
channels, including when a selected channel has no eligible release.

## Check, preview, apply, undo

```bash
magi-suite-update check
magi-suite-update guide
magi-suite-update preview --preset default
magi-suite-update apply --plan PLAN_ID --yes
magi-suite-update status --json
magi-suite-update undo --yes
```

Preview stages the resolved commit, verifies that checkout, runs the staged
installer in read-only mode, reports migration applicability, and prints the
exact file plan. Apply accepts only that preview's short-lived ID. The staged
transactional installer captures every replaced target, validates the result,
and automatically rolls back a failed apply. Successful apply records the
installer snapshot; `undo` restores that exact snapshot.

`guide` runs check and preview together, then requires typing `APPLY`. If the
resolved semantic version is older than the installed version it instead
requires typing `DOWNGRADE`, and the noninteractive apply form additionally
requires `--allow-downgrade`. No confirmation means no mutation.

Resolution cache lives under
`~/.local/state/evangelion-rice/suite-update/`. When the network is unavailable,
`check` clearly reports cached/offline evidence. A stale resolution may be
inspected but cannot be staged or applied; reconnect and check again. Channel
selection is stored in `~/.config/omarchy/evangelion-update.json` and is
preserved across suite installations.

Stable is a stability policy, not a claim that every tag is cryptographically
signed. Review the displayed signature and release-gate evidence before apply.
