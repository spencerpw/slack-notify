#!/bin/bash

CONFIG="$HOME/.claude/slack-notify-config"

if [ ! -f "$CONFIG" ]; then
  echo "⚠️ slack-notify: Not configured. Run /slack-notify:configure to set up." >&2
fi

exit 0
