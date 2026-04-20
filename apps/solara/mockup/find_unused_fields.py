"""Find unused class fields in fortune_overlays painter files.

各クラスの final フィールド一覧を抽出し、クラス外（または draw メソッド内）で
実際に参照されているかを確認する簡易チェック。
"""
from pathlib import Path
import re

OVERLAYS_DIR = Path(__file__).resolve().parents[1] / "lib" / "widgets" / "fortune_overlays"


def extract_classes(content: str):
    """Extract {class_name: {field_name: line}} from content."""
    result = {}
    # Find class declarations with field definitions
    # Pattern: class _X { ... final double a, b, c; ... final _Y y; ... }
    for m in re.finditer(r"class\s+(\w+)\s*(?:extends\s+\w+\s*)?\{", content):
        name = m.group(1)
        # Skip painter class (too much to scan)
        if "Painter" in name and "Builder" not in name:
            continue
        start = m.end()
        # Find matching closing brace (simple: balance counting)
        depth = 1
        i = start
        while i < len(content) and depth > 0:
            if content[i] == "{":
                depth += 1
            elif content[i] == "}":
                depth -= 1
            i += 1
        body = content[start:i - 1]
        # Only classes whose body contains "final" fields
        # Extract fields: "final TYPE name[, name2];" or "final TYPE a, b, c;"
        fields = []
        for fm in re.finditer(
            r"final\s+(?:\w+<[^>]+>|\w+\??)\s+(\w+(?:\s*,\s*\w+)*)\s*;",
            body,
        ):
            names = [n.strip() for n in fm.group(1).split(",")]
            fields.extend(names)
        if fields:
            result[name] = fields
    return result


def main():
    print(f"Scanning {OVERLAYS_DIR}...")
    issues = []
    for p in sorted(OVERLAYS_DIR.glob("*.dart")):
        content = p.read_text(encoding="utf-8")
        classes = extract_classes(content)
        if not classes:
            continue
        print(f"\n--- {p.name} ---")
        for cls, fields in classes.items():
            for field in fields:
                # How many times is this field referenced outside the declaration?
                # Patterns: .field or f.field or p.field etc.
                # Count total matches, subtract 1 for the declaration & 1 for constructor param reference
                pattern = r"\." + re.escape(field) + r"\b"
                refs = len(re.findall(pattern, content))
                # Also count "required this.field" (constructor)
                this_refs = len(re.findall(r"this\." + re.escape(field) + r"\b", content))
                external_refs = refs - this_refs  # outside constructor
                if external_refs == 0:
                    issues.append((p.name, cls, field))
                    print(f"  UNUSED: {cls}.{field}")
                else:
                    pass  # used - don't print
    print(f"\n---\nTotal unused fields: {len(issues)}")
    if issues:
        for f, c, n in issues:
            print(f"  {f} -> {c}.{n}")


if __name__ == "__main__":
    main()
