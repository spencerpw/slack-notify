---
description: Set up Slack credentials for slack-notify
allowed-tools:
  - Bash
  - Read
---

Help the user configure the slack-notify plugin.

1. Check if `~/.claude/slack-notify-config` exists.
   - If it exists, read it and show the current `SLACK_USER_ID`. Ask the user if they want to reconfigure.
   - If the user says no, stop here.
2. Run `bash ${CLAUDE_PLUGIN_ROOT}/setup.sh` to configure credentials interactively.
3. Report success or failure based on the exit code and output of the script.
