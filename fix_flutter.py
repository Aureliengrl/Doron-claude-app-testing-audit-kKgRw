import re

path = "lib/pages/new_pages/search_page/search_page_widget.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Fix arrowDown2
content = content.replace("IconlyLight.arrowDown2", "IconlyLight.arrowDown")

# 2. Fix CustomScrollView without Stack
# If Stack children has CustomScrollView, and then Positioned, maybe there's a trailing comma issue?
# Actually, the error "Too many positional arguments: 0 allowed, but 1 found" at Container means `Container(...)` was called instead of `child: Container(...)` or similar.
# "lib/pages/new_pages/search_page/search_page_widget.dart:714:23: Error: Too many positional arguments"
# Let's search for "child: Container(" -> wait, it says "child: Container(" is too many positional arguments??
# No! `Container` has NO positional arguments. It must be `Container(child: ...)` not `Container(something)`.
# Ah! Did someone write `Container(child)` instead of `Container(child: child)`?

with open("temp.dart", "w", encoding="utf-8") as f:
    f.write(content)
