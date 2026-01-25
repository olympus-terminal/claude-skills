---
description: Export current session to readable .log file
---

Export the current Claude Code session to a readable .log file in the current directory.

Run: `python3 ~/.claude/commands/export_session.py "$cwd"`

This will create a timestamped log file like `session_log_20260125_154801.log` containing all user/assistant messages from this session.

The script:
1. Finds the session file in ~/.claude/projects/
2. Extracts all user and assistant messages
3. Formats them with timestamps in a readable format
4. Saves to the current project directory
