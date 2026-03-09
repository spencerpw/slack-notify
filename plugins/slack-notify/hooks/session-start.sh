#!/bin/bash

CONFIG="$HOME/.claude/slack-notify-config"

if [ ! -f "$CONFIG" ]; then
  echo '{"systemMessage":"⚠️ slack-notify: Not configured. Run /slack-notify:configure to set up."}'
fi

exit 0
