#!/usr/bin/env python3
"""Checks that the Cottage Butter design system is consistent.

Run from anywhere:  python3 scripts/check_design_tokens.py

1. tokens.json colors match the colorsets (light and dark) in Butter/DesignSystem/Colors.xcassets.
2. Every Color.butter* token in tokens.json has a `static let` in ButterTheme.swift.
3. Feature code (everything under Butter/ except Butter/DesignSystem) uses no hard-coded
   colors, no fixed font sizes and no custom fonts.

Exit status is 1 when any check fails.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOKENS = ROOT / "docs/design/tokens.json"
COLORSETS = ROOT / "Butter/DesignSystem/Colors.xcassets"
THEME = ROOT / "Butter/DesignSystem/ButterTheme.swift"
APP = ROOT / "Butter"
DESIGN_SYSTEM = ROOT / "Butter/DesignSystem"

errors = []


def fail(msg):
    errors.append(msg)


def hex_to_floats(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def colorset_components(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    result = {}
    for entry in data["colors"]:
        comps = entry["color"]["components"]
        rgb = [float(comps["red"]), float(comps["green"]), float(comps["blue"])]
        if entry.get("appearances"):
            result["dark"] = rgb
        else:
            result["light"] = rgb
    return result


def check_colors(tokens):
    for name, tok in tokens["color"].items():
        asset = tok["asset"]
        path = COLORSETS / f"{asset}.colorset" / "Contents.json"
        if not path.exists():
            fail(f"[color] {name}: missing colorset {asset}.colorset")
            continue
        comps = colorset_components(path)
        for mode in ("light", "dark"):
            if mode not in comps:
                fail(f"[color] {asset}: missing {mode} variant")
                continue
            expected = hex_to_floats(tok[mode])
            if any(abs(a - b) > 0.5 / 255 + 1e-6 for a, b in zip(comps[mode], expected)):
                fail(f"[color] {asset} {mode}: colorset {comps[mode]} != tokens {tok[mode]}")


def check_swift_names(tokens):
    theme = THEME.read_text(encoding="utf-8")
    for name, tok in tokens["color"].items():
        swift = tok["swift"].split(".")[-1]
        if not re.search(rf"static let {re.escape(swift)}\b", theme):
            fail(f"[swift] {tok['swift']} not declared in ButterTheme.swift")


FORBIDDEN = [
    (re.compile(r"Color\(red:|Color\(\.sRGB|UIColor\(red:|Color\(uiColor:"), "hard-coded color"),
    (re.compile(r"#[0-9A-Fa-f]{6}\b"), "hex color literal"),
    (re.compile(r"\.font\(\.system\(size:"), "fixed font size (use a Dynamic Type text style)"),
    (re.compile(r"\.font\(\.custom\("), "custom font (use system or Font.butterDisplay)"),
]


def check_feature_code():
    for path in APP.rglob("*.swift"):
        if DESIGN_SYSTEM in path.parents:
            continue
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for pattern, label in FORBIDDEN:
                if pattern.search(line):
                    rel = path.relative_to(ROOT)
                    fail(f"[code] {rel}:{lineno}: {label}: {line.strip()}")


def main():
    tokens = json.loads(TOKENS.read_text(encoding="utf-8"))
    check_colors(tokens)
    check_swift_names(tokens)
    check_feature_code()
    if errors:
        print("Design system check failed:")
        for e in errors:
            print("  " + e)
        return 1
    print("Design system check passed: "
          f"{len(tokens['color'])} color tokens, feature code clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
