# Community compatibility testing

This optional protocol helps Omarchy users report compatibility observations
from environments other than the reference ThinkPad T480. Community reports
improve future releases, but are not required to install or release v1.4.

## What qualifies

A useful report comes from a clean environment: a new user account, disposable
installation, or machine that has never received the developer's live
configuration. GitHub Actions provides repeatable CI evidence but does not
claim to represent additional physical Omarchy hardware.

Do not test on a machine where losing the current desktop configuration would
be unacceptable. Review the installer dry-run before applying it.

## Run the protocol

Clone the exact current release, then collect a local evidence bundle:

```bash
git clone --branch v1.4.1 --depth 1 \
  https://github.com/so1omon563/evangelion-omarchy-rice.git
cd evangelion-omarchy-rice
./beta-report.sh prepare ~/evangelion-beta --preset default
./beta-report.sh install ~/evangelion-beta --preset default
omarchy theme set evangelion
./beta-report.sh validate ~/evangelion-beta
./beta-report.sh rollback ~/evangelion-beta
./beta-report.sh review ~/evangelion-beta
# Edit review.json: use a broad hardware class, add feedback, and set all
# three confirmations true only after inspecting every field.
./beta-report.sh finalize ~/evangelion-beta
./beta-report.sh open-issue ~/evangelion-beta
```

`prepare` is read-only. `install` performs the explicitly selected installer
transaction, and `rollback` restores that transaction's recorded snapshot.
Run those two mutating steps only when you are ready. You may replace
`--preset default` with another documented preset or component selection, but
use the same selection for `prepare` and `install`.

After rollback, confirm that the prior theme, shell, Hyprland configuration,
services, and shell startup behavior are restored. `review` creates an explicit
questionnaire and publication attestations. `finalize` refuses to create a
report until that review is complete and validates the stable v2 schema and
privacy invariants. `open-issue` uses your default browser and never uploads
anything automatically. The `*.log` files remain local diagnostic material.

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

Maintainers follow [COMMUNITY_REPORT_TRIAGE.md](COMMUNITY_REPORT_TRIAGE.md).
Accepted observations are added to the versioned
[`compatibility/community-matrix.json`](compatibility/community-matrix.json);
reports remain optional evidence and never become a release gate.

## Release evidence

The machine-readable decision record is
[`release/v1.4.0.json`](release/v1.4.0.json). v1.4 was released after:

- source CI is green for the exact release commit;
- the isolated clean-user install, validation, repeat-install, failure recovery,
  rollback, and cleanup lifecycle passes;
- transactional installer and responsive display-matrix tests pass;
- the reference Omarchy system passes live validation;
- known blockers and the documented compatibility matrix are reviewed;
- release media and migration notes pass review.
