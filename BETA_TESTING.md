# v1.1 external beta

The `v1.1.0-rc.1` beta is for Omarchy users who did not develop or install the
project on the original ThinkPad T480. The final `v1.1.0` tag is gated on two
independent reports from clean Omarchy environments.

## What qualifies

Together, accepted reports must cover at least two display/scale combinations
and one materially different hardware profile. A clean environment may be a
new user account, disposable installation, or machine that has never received
the developer's live configuration. A GitHub Actions Ubuntu runner is useful
CI evidence, but is not an external Omarchy beta environment.

Do not test on a machine where losing the current desktop configuration would
be unacceptable. Review the installer dry-run before applying it.

## Run the protocol

Clone the release candidate, then collect a local evidence bundle:

```bash
git clone --branch v1.1.0-rc.1 --depth 1 \
  https://github.com/so1omon563/evangelion-omarchy-rice.git
cd evangelion-omarchy-rice
./beta-report.sh prepare ~/evangelion-beta --preset default
./beta-report.sh install ~/evangelion-beta --preset default
omarchy theme set evangelion
./beta-report.sh validate ~/evangelion-beta
./beta-report.sh rollback ~/evangelion-beta
./beta-report.sh finalize ~/evangelion-beta
```

`prepare` is read-only. `install` performs the explicitly selected installer
transaction, and `rollback` restores that transaction's recorded snapshot.
Run those two mutating steps only when you are ready. You may replace
`--preset default` with another documented preset or component selection, but
use the same selection for `prepare` and `install`.

After rollback, confirm that the prior theme, shell, Hyprland configuration,
services, and shell startup behavior are restored. The bundle's `report.json`
contains shareable status evidence; the `*.log` files remain local diagnostic
material.

## Report the result

[Open a beta report](https://github.com/so1omon563/evangelion-omarchy-rice/issues/new?template=beta-report.yml)
and attach or paste `report.json`. Describe hardware as a broad class (for
example, “AMD desktop with discrete GPU”); provide display resolution and
scale, component selection, install/validation/rollback outcomes, any blocker
and its resolution, and qualitative feedback.

Privacy rules:

- Do not upload raw logs without reviewing and redacting them.
- Remove usernames, home paths, hostnames, serial numbers, IP/MAC addresses,
  account names, browser history, notification text, and private window titles.
- Use a generic hardware class; exact serial/model identifiers are unnecessary.
- Screenshots are optional. Crop them and inspect every visible surface first.

Maintainers accept a report only when preflight, install, validation, rollback,
display/scale, hardware class, chosen components, and feedback are all present.
Blockers are documented in the issue and either fixed in a new RC or converted
into explicit compatibility guidance. The compatibility matrix is updated from
accepted observations before the final release.

## Final-release gate

The machine-readable gate is [`release/v1.1.0.json`](release/v1.1.0.json).
`v1.1.0` may be tagged only after:

- source CI is green for the exact candidate commit;
- two qualifying external reports are accepted;
- their combined display and hardware coverage meets the criteria above;
- install, validation, and rollback pass on both environments;
- reported blockers and the observed compatibility matrix are resolved;
- release media and migration notes pass review.
