# Canonical visual regression harness

The harness renders deterministic fictional MAGI surfaces without reading the
live desktop, home directory, network, processes, or hardware. The pairwise
matrix covers every affinity family, Full/Reduced/Off motion, theme variants,
multiple resolutions/scales, safety states, and available/stale/unavailable
capabilities without multiplying every dimension into hundreds of images.

```bash
./tests/visual-regression.py
```

Failures retain `actual.png`, `expected.png`, `diff.png`, and `report.json`
under `test-results/visual-regression/`. Each case declares a maximum changed
pixel percentage and global fuzz threshold. Masks are narrowly named rectangles
for fields that are intentionally dynamic in a future live-capture adapter.

Baseline changes require an explicit approval environment and flag:

```bash
VISUAL_BASELINE_APPROVED=1 ./tests/visual-regression.py --approve
git diff -- visual-regression/baselines visual-regression/baselines.json
```

Approval rewrites the PNGs and their SHA-256 provenance manifest. Reviewers
must inspect the images and manifest diff; CI never approves baselines.
