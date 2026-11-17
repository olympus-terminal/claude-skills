---
description: View and analyze the most recent screenshot
---

View and analyze the most recent screenshot.

Steps:
1. Find the most recent screenshot by searching common locations: run `find ~/Pictures ~/Desktop ~/Downloads -maxdepth 2 -name "Screenshot*" -type f 2>/dev/null | xargs ls -lt 2>/dev/null | head -1`
2. Use the Read tool to view the latest screenshot file
3. Provide analysis or answer questions about what you see in the image
