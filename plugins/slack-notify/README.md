# slack-notify

Claude Code plugin that sends you Slack DMs when Claude needs your attention.

## What it does

- **Stop hook** — DMs you when Claude finishes a task or asks a question
- **PermissionRequest hook** — DMs you when Claude needs tool approval (e.g. Bash commands, file edits)
- **Session start check** — Reminds you to configure if credentials are missing

Each session gets a random emoji so you can visually group messages from the same session.

## Quick Start

1. Install from marketplace:
   ```bash
   claude plugin install slack-notify
   ```

2. Configure credentials:
   ```
   /slack-notify:configure
   ```

3. Done! You'll now receive Slack DMs when Claude needs attention.

## Commands

| Command | Description |
|---|---|
| `/slack-notify:configure` | Set up or reconfigure Slack credentials |
| `/slack-notify:test` | Send a test DM to verify everything works |
| `/slack-notify:status` | Show config status, error log, and active hooks |

## Prerequisites

- `python3`
- `curl`
- `claude` CLI (authenticated)
- `op` (1Password CLI) — used to fetch the Slack bot token

## Slack App Scopes

Your Slack bot needs these OAuth scopes:

- `chat:write` — send DMs
- `users:read.email` — look up your Slack user ID from your email

## Uninstall

```bash
claude plugin uninstall slack-notify
rm -f ~/.claude/slack-notify-config ~/.claude/slack-notify.log
```

## Troubleshooting

- Run `/slack-notify:test` to validate your token and send a test message
- Run `/slack-notify:status` to check config and recent errors
- Slack API errors are logged to `~/.claude/slack-notify.log`

## License

MIT
