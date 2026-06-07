import re

path = "lib/pages/new_pages/search_page/search_page_widget.dart"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# 1. Fix IconlyLight.arrowDown2 -> arrowDown
for i, line in enumerate(lines):
    if "IconlyLight.arrowDown2" in line:
        lines[i] = line.replace("IconlyLight.arrowDown2", "IconlyLight.arrowDown")

# 2. Fix 'Expected an identifier, but got ']'' on lines 254, 881, 1756, 1780
# Often this means `],` or `)]` after a missing expression or comma trailing
# Wait, `],` alone is valid in Dart (e.g. `[1, 2, ],`). But if it's `,,]` it's invalid.
for target_line in [254, 881, 1756, 1780]:
    i = target_line - 1
    if i < len(lines):
        print(f"Line {target_line}: {lines[i].strip()}")

# Let's fix line 1836 (Can't find ')' to match '(') -> maybe showDialog<bool>( is missing `);`
# Or there's a missing parenthesis in `border: OutlineInputBorder(...)`
for target_line in [1836, 1668, 714]:
    i = target_line - 1
    if i < len(lines):
        print(f"Line {target_line}: {lines[i].strip()}")

with open("temp.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)
