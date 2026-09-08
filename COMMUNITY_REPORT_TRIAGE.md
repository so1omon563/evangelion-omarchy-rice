# Community compatibility report triage

Community reports are opt-in observations, not release gates. Never treat a
missing hardware class, an empty matrix, or an unresolved community issue as a
reason to block a release. A credible safety or data-loss report instead enters
the project's normal defect process.

## Intake

1. Require schema v2 and a repository issue URL. Reject raw logs, unreviewed
   screenshots, hostnames, usernames, home paths, serial/MAC/IP addresses, and
   account or notification content; ask the reporter to remove the attachment.
2. Download only the reviewed `report.json` and validate it locally:

   ```sh
   tools/accept-compatibility-report --validate-only /path/to/report.json
   ```

3. Compare candidate commit/channel, component selection, coarse displays and
   capabilities, all five lifecycle results, restoration confirmation, and the
   qualitative issue list. A blocked lifecycle is valid evidence when clearly
   described; `all_passed` is not required for intake.
4. Deduplicate by environment/candidate fingerprint, request clarification in
   the public issue, and link actionable defects separately. Do not infer broad
   support from one observation.

## Accepting an observation

After privacy and evidence review, update the versioned matrix on a normal
branch and review its diff:

```sh
tools/accept-compatibility-report /path/to/report.json \
  --issue https://github.com/so1omon563/evangelion-omarchy-rice/issues/123
git diff -- compatibility/community-matrix.json
```

The updater records only coarse hardware class, architecture, display geometry,
boolean/count capabilities, selected components, lifecycle results, and issue
outcomes. It excludes free-form feedback from the matrix to limit accidental
data propagation. Maintainers may remove or correct an observation through a
reviewed repository change; the public issue remains the provenance source.

## Interpretation

`verified-reference` means a maintainer exercised the live reference system.
Community rows mean only that a reviewed reporter observed the recorded result
on that candidate. They are not certification, endorsement, or a promise of
future support. Release records must continue to state `required_reports: 0`
and `optional-post-release`.
