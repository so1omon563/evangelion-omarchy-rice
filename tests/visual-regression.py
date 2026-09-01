#!/usr/bin/env python3
"""Render and compare privacy-safe canonical MAGI surface fixtures."""
import argparse
import hashlib
import html
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VISUAL = ROOT / "visual-regression"
MATRIX = json.loads((VISUAL / "matrix.json").read_text())
BASELINES = VISUAL / "baselines"
MANIFEST = VISUAL / "baselines.json"
OUTPUT = Path(os.environ.get("EVANGELION_VISUAL_RESULTS", ROOT / "test-results/visual-regression"))
IMAGE = shutil.which("magick") or shutil.which("convert")

PALETTES = {
    "neutral": ("#9cf23a", "#8f4bc8", "#0b0810", "#e8e1ef", "NERV / MAGI"),
    "unit-00-prototype": ("#f6c744", "#3ba7d8", "#0b0905", "#f2e9d2", "EVA-00 PROTOTYPE"),
    "unit-00-refit": ("#55d9ff", "#f2f6ff", "#050b12", "#e8f1ff", "EVA-00 REFIT"),
    "unit-01": ("#9cf23a", "#8f4bc8", "#0b0810", "#e8e1ef", "EVA-01 TEST TYPE"),
    "unit-02": ("#ff5a36", "#f6a52f", "#0d0504", "#f5e5df", "EVA-02 PRODUCTION"),
}
STATE = {"nominal": ("NOMINAL", "#9cf23a"), "warning": ("CAUTION", "#f6c744"), "critical": ("CONDITION RED", "#ff4055")}


def svg(case):
    width, height = int(case.get("width", MATRIX["defaults"]["width"])), int(case.get("height", MATRIX["defaults"]["height"]))
    accent, secondary, dark, foreground, label = PALETTES[case["affinity"]]
    status, state_color = STATE[case["state"]]
    variant = case["variant"]
    background = "#000000" if variant == "oled" else "#f1ead8" if variant == "daylight" else dark
    text = "#17131d" if variant == "daylight" else foreground
    border = "#ffffff" if variant == "high-contrast" else accent
    capability = {"available": "LINK ACTIVE", "stale": "CACHE STALE", "unavailable": "LINK UNAVAILABLE"}[case["capability"]]
    panel_w = max(260, (width - 72) // 3); panel_y = 168; panel_h = max(180, height - 220)
    def esc(value): return html.escape(str(value))
    panels = []
    titles = (("SYSTEM TELEMETRY", status), ("OPERATIONS", capability), ("MOTION CONTROL", case["motion"].upper()))
    for index, (title, value) in enumerate(titles):
        x = 24 + index * (panel_w + 12)
        panels.append(f'<rect x="{x}" y="{panel_y}" width="{panel_w}" height="{panel_h}" fill="{background}" fill-opacity=".92" stroke="{border}" stroke-width="2"/>')
        panels.append(f'<text x="{x+20}" y="{panel_y+36}" class="heading" fill="{accent}">{esc(title)}</text>')
        panels.append(f'<text x="{x+20}" y="{panel_y+86}" class="value" fill="{state_color if index == 0 else text}">{esc(value)}</text>')
        for row in range(4):
            ry = panel_y + 125 + row * 42
            panels.append(f'<text x="{x+20}" y="{ry}" class="caption" fill="{text}">{row+1:02d} // FICTIONAL TEST CHANNEL</text>')
            panels.append(f'<rect x="{x+20}" y="{ry+10}" width="{panel_w-40}" height="4" fill="{secondary}" opacity="{.25 + row*.15}"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<style>.label{{font:700 14px 'DejaVu Sans Mono';letter-spacing:3px}}.heading{{font:700 15px 'DejaVu Sans Mono';letter-spacing:3px}}.value{{font:700 25px 'DejaVu Sans Mono'}}.caption{{font:11px 'DejaVu Sans Mono';letter-spacing:1px}}</style>
<rect width="100%" height="100%" fill="{background}"/><rect x="0" y="0" width="100%" height="46" fill="#050507"/>
<text x="20" y="29" class="label" fill="{accent}">NERV // CANONICAL VISUAL FIXTURE</text>
<text x="{width//2-25}" y="29" class="caption" fill="{text}">12:34:56</text>
<text x="{width-310}" y="29" class="caption" fill="{secondary}">{esc(case['id'])}</text>
<text x="24" y="92" class="heading" fill="{accent}">{esc(label)}</text>
<text x="24" y="132" class="value" fill="{text}">MAGI INTERFACE // {esc(variant.upper())}</text>
<text x="{width-280}" y="132" class="caption" fill="{state_color}">{esc(status)} // SCALE {case.get('scale', 1.0)}</text>
{''.join(panels)}
<rect x="0" y="{height-32}" width="100%" height="32" fill="#050507"/><text x="18" y="{height-12}" class="caption" fill="{accent}">DEMO DATA // NO LIVE DESKTOP INPUT</text>
</svg>'''


def render(case, output):
    content = svg(case)
    lowered = content.lower()
    for prohibited in MATRIX["privacy"]["prohibited"]:
        if prohibited.lower() in lowered:
            raise ValueError(f"Private field marker in visual fixture: {prohibited}")
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as stream:
        stream.write(content); source = Path(stream.name)
    try:
        subprocess.run(["rsvg-convert", "--output", str(output), str(source)], check=True, capture_output=True)
        subprocess.run([IMAGE, str(output), "-strip", f"PNG24:{output}"], check=True, capture_output=True)
    finally: source.unlink(missing_ok=True)


def masked(source, target, case):
    shutil.copy2(source, target)
    width = int(case.get("width", MATRIX["defaults"]["width"]))
    for mask in MATRIX["masks"]:
        # Clock mask is centered relative to the canonical width.
        x = width // 2 - 25 if mask["name"] == "clock-seconds" else mask["x"]
        subprocess.run([IMAGE, str(target), "-fill", "#000000", "-draw",
                        f"rectangle {x},{mask['y']} {x+mask['width']},{mask['y']+mask['height']}", str(target)], check=True, capture_output=True)


def compare(expected, actual, diff, case):
    with tempfile.TemporaryDirectory() as directory:
        expected_masked, actual_masked = Path(directory) / "expected-masked.png", Path(directory) / "actual-masked.png"
        expected_normalized, actual_normalized = Path(directory) / "expected.png", Path(directory) / "actual.png"
        masked(expected, expected_masked, case); masked(actual, actual_masked, case)
        # Normalize sub-pixel glyph antialiasing across librsvg/FreeType builds.
        # The area threshold remains strict and the failure-path test proves
        # that a visible structural change still fails after normalization.
        sigma = MATRIX["defaults"]["normalization_blur_sigma"]
        for source, target in ((expected_masked, expected_normalized), (actual_masked, actual_normalized)):
            subprocess.run([IMAGE, str(source), "-blur", f"0x{sigma}", str(target)], check=True, capture_output=True)
        metric = subprocess.run(["compare", "-metric", "AE", "-fuzz", f"{MATRIX['defaults']['fuzz_percent']}%",
                                 str(expected_normalized), str(actual_normalized), str(diff)],
                                text=True, capture_output=True)
        changed = int(float((metric.stderr.strip() or "0").split()[0]))
    pixels = int(case.get("width", MATRIX["defaults"]["width"])) * int(case.get("height", MATRIX["defaults"]["height"]))
    percent = changed * 100 / pixels
    return percent, percent <= float(case.get("tolerance_percent", MATRIX["defaults"]["tolerance_percent"]))


def main():
    parser = argparse.ArgumentParser(); parser.add_argument("--approve", action="store_true"); parser.add_argument("--self-test", action="store_true"); args = parser.parse_args()
    if not IMAGE or not shutil.which("compare") or not shutil.which("rsvg-convert"):
        raise SystemExit("ImageMagick and rsvg-convert are required")
    cases = MATRIX["cases"]
    required = {"affinity": set(PALETTES), "motion": {"full", "reduced", "off"},
                "variant": {"default", "oled", "daylight", "high-contrast"},
                "state": set(STATE), "capability": {"available", "stale", "unavailable"}}
    for field, values in required.items():
        if {case[field] for case in cases} != values:
            raise SystemExit(f"Visual matrix does not cover every {field}")
    if args.approve and os.environ.get("VISUAL_BASELINE_APPROVED") != "1": raise SystemExit("Set VISUAL_BASELINE_APPROVED=1 to approve baselines")
    OUTPUT.mkdir(parents=True, exist_ok=True); BASELINES.mkdir(parents=True, exist_ok=True)
    results = []; hashes = {}
    for case in cases:
        case_dir = OUTPUT / case["id"]; case_dir.mkdir(parents=True, exist_ok=True)
        actual, expected, diff = case_dir / "actual.png", BASELINES / f"{case['id']}.png", case_dir / "diff.png"
        render(case, actual)
        if args.approve: shutil.copy2(actual, expected)
        if not expected.exists(): results.append({"id": case["id"], "status": "missing-baseline"}); continue
        shutil.copy2(expected, case_dir / "expected.png")
        percent, passed = compare(expected, actual, diff, case)
        results.append({"id": case["id"], "status": "passed" if passed else "failed", "changed_percent": round(percent, 6),
                        "tolerance_percent": case.get("tolerance_percent", MATRIX["defaults"]["tolerance_percent"])})
        hashes[expected.name] = hashlib.sha256(expected.read_bytes()).hexdigest()
    self_test = None
    if args.self_test and results:
        case = MATRIX["cases"][0]; case_dir = OUTPUT / case["id"]
        perturbed, proof = OUTPUT / "self-test-perturbed.png", OUTPUT / "self-test-diff.png"
        shutil.copy2(case_dir / "actual.png", perturbed)
        subprocess.run([IMAGE, str(perturbed), "-fill", "#ff00ff", "-draw", "rectangle 80,80 180,180", str(perturbed)], check=True, capture_output=True)
        percent, accepted = compare(BASELINES / f"{case['id']}.png", perturbed, proof, case)
        self_test = {"status": "passed" if not accepted and proof.exists() else "failed", "changed_percent": round(percent, 6), "diff": proof.name}
    report = {"schema_version": 1, "renderer_version": MATRIX["renderer_version"],
              "status": "passed" if all(r["status"] == "passed" for r in results) and (not self_test or self_test["status"] == "passed") else "failed",
              "cases": results, "privacy": MATRIX["privacy"], "failure_path_self_test": self_test}
    (OUTPUT / "report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    if args.approve:
        MANIFEST.write_text(json.dumps({"schema_version": 1, "renderer_version": MATRIX["renderer_version"], "files": hashes}, indent=2, sort_keys=True) + "\n")
    else:
        manifest = json.loads(MANIFEST.read_text())
        if manifest.get("files") != hashes: raise SystemExit("Baseline provenance mismatch; approval workflow required")
    if report["status"] != "passed": raise SystemExit("Visual regression failed; inspect test-results/visual-regression")
    print(f"PASS  {len(results)} canonical visual baselines")


if __name__ == "__main__": main()
