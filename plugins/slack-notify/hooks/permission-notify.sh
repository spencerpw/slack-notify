#!/bin/bash

CONFIG="$HOME/.claude/slack-notify-config"

[ -f "$CONFIG" ] || exit 0

SLACK_TOKEN=$(grep '^SLACK_TOKEN=' "$CONFIG" | cut -d= -f2-)
SLACK_USER_ID=$(grep '^SLACK_USER_ID=' "$CONFIG" | cut -d= -f2-)

[ -n "$SLACK_TOKEN" ] && [ -n "$SLACK_USER_ID" ] || exit 0

PAYLOAD=$(cat)
SESSION_ID=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
CWD=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd','unknown'))" 2>/dev/null)

SESSION_EMOJI=$(python3 -c "
import hashlib, sys
emojis = ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐙',
          '🦋','🐢','🦄','🐝','🦀','🦞','🦩','🦚','🦜','🐊','🦭','🦦','🦥','🐿️','🦔',
          '🌵','🌴','🍄','🌊','⚡','🔥','🌈','❄️','🌙','☀️','🪐','🌋','🗻','🏔️','🌺']
h = int(hashlib.md5(sys.argv[1].encode()).hexdigest(), 16)
print(emojis[h % len(emojis)])
" "$SESSION_ID" 2>/dev/null)

DIR=$(basename "$CWD")

python3 - "$PAYLOAD" "$SLACK_TOKEN" "$SLACK_USER_ID" "$SESSION_EMOJI" "$DIR" << 'PYEOF'
import json, sys, urllib.request

raw_payload, slack_token, slack_user_id, session_emoji, project_dir = sys.argv[1:6]

payload = json.loads(raw_payload)
tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", {})

# Build context-aware message based on tool type
if tool_name == "Bash":
    cmd = tool_input.get("command", "")
    first_line = cmd.split("\n")[0][:80]
    msg = f"\U0001f5a5\ufe0f `{first_line}`"
elif tool_name in ("Edit", "MultiEdit"):
    path = tool_input.get("file_path", "")
    filename = path.rsplit("/", 1)[-1] if path else "file"
    msg = f"\U0001f4dd Edit `{filename}`"
elif tool_name == "Write":
    path = tool_input.get("file_path", "")
    filename = path.rsplit("/", 1)[-1] if path else "file"
    msg = f"\U0001f4dd Write `{filename}`"
elif tool_name == "NotebookEdit":
    path = tool_input.get("file_path", "")
    filename = path.rsplit("/", 1)[-1] if path else "notebook"
    msg = f"\U0001f4d3 Edit `{filename}`"
elif tool_name.startswith("mcp__"):
    parts = tool_name.split("__")
    readable = f"{parts[1]}: {parts[2]}" if len(parts) >= 3 else tool_name
    msg = f"\U0001f50c `{readable}`"
else:
    msg = f"\U0001f527 `{tool_name}`"

slack_text = f"{session_emoji} *{project_dir}:* {msg} — needs your attention"

data = json.dumps({"channel": slack_user_id, "text": slack_text}).encode()
req = urllib.request.Request(
    "https://slack.com/api/chat.postMessage",
    data=data,
    headers={"Authorization": f"Bearer {slack_token}", "Content-Type": "application/json; charset=utf-8"},
)
try:
    resp = urllib.request.urlopen(req)
    result = json.loads(resp.read())
    if not result.get("ok"):
        import os
        from datetime import datetime
        ts = datetime.now().isoformat()
        with open(os.path.expanduser("~/.claude/slack-notify.log"), "a") as f:
            f.write(f"[{ts}] {result.get('error','unknown')}\n")
except Exception as e:
    import os
    from datetime import datetime
    ts = datetime.now().isoformat()
    with open(os.path.expanduser("~/.claude/slack-notify.log"), "a") as f:
        f.write(f"[{ts}] {e}\n")
PYEOF
