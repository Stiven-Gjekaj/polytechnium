"""Checks the text of the app in English and in Albanian.

The key of each text is the English text in a call such as tr("Save") in the
Swift code. The script writes the English file from these keys. It fails when
the Albanian file does not have a key, or has a key that the code does not use.

    python3 scripts/strings.py          writes en.lproj and checks sq.lproj
    python3 scripts/strings.py --check  only checks both files
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [ROOT / "App", ROOT / "Shared", ROOT / "Widgets"]
RESOURCES = ROOT / "Shared" / "Resources"
CALL = re.compile(r'\btr\("((?:[^"\\]|\\.)*)"')
ENTRY = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";\s*$')


def keys_in_code():
    found = set()
    for folder in SOURCES:
        for path in folder.rglob("*.swift"):
            found.update(CALL.findall(path.read_text()))
    return found


def entries(path):
    result = {}
    for number, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*"):
            continue
        match = ENTRY.match(stripped)
        if not match:
            raise SystemExit(f"{path.name}:{number}: the line is not a string entry")
        if match.group(1) in result:
            raise SystemExit(f"{path.name}:{number}: the key is two times in the file")
        result[match.group(1)] = match.group(2)
    return result


def english(keys):
    lines = ["/* Written by scripts/strings.py from the keys in the code. Do not edit. */", ""]
    lines += [f'"{key}" = "{key}";' for key in sorted(keys)]
    return "\n".join(lines) + "\n"


def placeholders(text):
    return sorted(re.findall(r"%(?:\d+\$)?[@dfs]", text))


def main():
    keys = keys_in_code()
    english_path = RESOURCES / "en.lproj" / "Localizable.strings"
    albanian_path = RESOURCES / "sq.lproj" / "Localizable.strings"
    text = english(keys)
    if "--check" in sys.argv:
        if not english_path.exists() or english_path.read_text() != text:
            raise SystemExit("en.lproj is old. Run python3 scripts/strings.py")
    else:
        english_path.write_text(text)
    albanian = entries(albanian_path)
    missing = sorted(keys - albanian.keys())
    extra = sorted(albanian.keys() - keys)
    wrong = sorted(k for k in keys & albanian.keys() if placeholders(k) != placeholders(albanian[k]))
    for key in missing:
        print(f"sq.lproj has no text for: {key}")
    for key in extra:
        print(f"sq.lproj has a key that the code does not use: {key}")
    for key in wrong:
        print(f"sq.lproj has other placeholders for: {key}")
    if missing or extra or wrong:
        return 1
    print(f"{len(keys)} texts in English and Albanian")
    return 0


if __name__ == "__main__":
    sys.exit(main())
