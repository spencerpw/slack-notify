---
description: Show slack-notify configuration and error log status
allowed-tools:
  - Read
  - Bash
  - Glob
---

Show the current status of the slack-notify plugin.

1. **Config:** Check if `~/.claude/slack-notify-config` exists.
   - If yes, read it and show the `SLACK_USER_ID` (do NOT show the token). Report "Configured".
   - If no, report "Not configured — run `/slack-notify:configure`".

2. **Error log:** Check if `~/.claude/slack-notify.log` exists.
   - If yes, show the last 10 lines.
   - If no, report "No errors logged".

3. **Hooks:** Read `~/.claude/settings.json` and show which slack-notify hooks are currently registered (Stop, PermissionRequest, SessionStart).
