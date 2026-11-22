#!/usr/bin/env python3
"""Fails unless every SwiftUI View in Butter/ lives in a file with Light and Dark previews."""
import pathlib, re, sys

failures = []
views = 0
for path in sorted(pathlib.Path("Butter").rglob("*.swift")):
    text = path.read_text()
    names = re.findall(r"^\s*(?:private |fileprivate )?struct (\w+)(?:<[^>]*>)?\s*:\s*(?:[\w, ]*\b)?View\b", text, re.M)
    if not names:
        continue
    views += len(names)
    if len(names) > 1:
        failures.append(f"{path}: more than one View ({', '.join(names)}); give each its own file and previews")
    previews = re.findall(r'#Preview\("([^"]*)"\)', text)
    if not any("Light" in p for p in previews) or not any("Dark" in p for p in previews):
        failures.append(f"{path}: {names[0]} needs both a Light and a Dark #Preview")
    for name in names:
        if not re.search(rf"#Preview[^{{]*\{{[^#]*\b{name}\b", text, re.S):
            failures.append(f"{path}: previews don't show {name}")
    dark_blocks = re.findall(r'#Preview\("[^"]*Dark[^"]*"\)\s*\{(.*?)\n\}', text, re.S)
    if dark_blocks and not all(".preferredColorScheme(.dark)" in b for b in dark_blocks):
        failures.append(f"{path}: a Dark preview doesn't set .preferredColorScheme(.dark)")

print(f"Checked {views} views.")
if failures:
    print("\n".join(failures))
    sys.exit(1)
print("Every view has its own Light and Dark preview.")
