---
description: Send a test Slack DM to verify slack-notify is working
allowed-tools:
  - Bash
  - Read
---

Send a test Slack DM to verify the plugin is working.

1. Check if `~/.claude/slack-notify-config` exists. If not, tell the user to run `/slack-notify:configure` first and stop.
2. Read the config file to get `SLACK_TOKEN` and `SLACK_USER_ID`.
3. Validate the token by calling the Slack `auth.test` API:
   ```bash
   curl -s -H "Authorization: Bearer $SLACK_TOKEN" https://slack.com/api/auth.test
   ```
   Report whether the token is valid or expired/invalid.
4. If the token is valid, send a test DM:
   ```bash
   curl -s -X POST https://slack.com/api/chat.postMessage \
     -H "Authorization: Bearer $SLACK_TOKEN" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d '{"channel":"'$SLACK_USER_ID'","text":"🧪 Test message from slack-notify — everything is working!"}'
   ```
5. Report success. If any step fails, show the error and suggest:
   - Token invalid → re-run `/slack-notify:configure`
   - DM failed → check bot has `chat:write` scope and has been added to the workspace
