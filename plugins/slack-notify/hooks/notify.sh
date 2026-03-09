#!/bin/bash

CONFIG="$HOME/.claude/slack-notify-config"

# Skip silently if config doesn't exist
[ -f "$CONFIG" ] || exit 0

SLACK_TOKEN=$(grep '^SLACK_TOKEN=' "$CONFIG" | cut -d= -f2-)
SLACK_USER_ID=$(grep '^SLACK_USER_ID=' "$CONFIG" | cut -d= -f2-)

# Skip silently if either value is missing
[ -n "$SLACK_TOKEN" ] && [ -n "$SLACK_USER_ID" ] || exit 0

# Read JSON payload from stdin
PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)
SESSION_ID=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
CWD=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd','unknown'))" 2>/dev/null)

# Generate a consistent emoji from the session ID hash
SESSION_EMOJI=$(python3 -c "
import hashlib, sys
emojis = ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐙',
          '🦋','🐢','🦄','🐝','🦀','🦞','🦩','🦚','🦜','🐊','🦭','🦦','🦥','🐿️','🦔',
          '🌵','🌴','🍄','🌊','⚡','🔥','🌈','❄️','🌙','☀️','🪐','🌋','🗻','🏔️','🌺']
h = int(hashlib.md5(sys.argv[1].encode()).hexdigest(), 16)
print(emojis[h % len(emojis)])
" "$SESSION_ID" 2>/dev/null)

DIR=$(basename "$CWD")

# Build and send Slack message entirely in Python to avoid shell escaping issues
python3 - "$TRANSCRIPT" "$SLACK_TOKEN" "$SLACK_USER_ID" "$SESSION_EMOJI" "$DIR" << 'PYEOF'
import json, re, sys, urllib.request

transcript_path, slack_token, slack_user_id, session_emoji, project_dir = sys.argv[1:6]

# Extract last assistant text message
text = ""
if transcript_path:
    try:
        for line in reversed(open(transcript_path).readlines()):
            try:
                obj = json.loads(line)
                if obj.get("type") == "assistant":
                    for block in obj.get("message", {}).get("content", []):
                        if block.get("type") == "text":
                            text = block["text"].strip()
                            break
                if text:
                    break
            except:
                pass
    except:
        pass

question_phrases = [
    "would you like", "do you want", "should i", "shall i",
    "can you", "could you", "what would", "which ", "how would",
    "do you have", "are you ", "is there ", "have you ",
    "what do you", "what should", "what are ",
    "which one", "which would", "pick one", "choose one",
    "let me know", "please confirm", "please provide",
    "please share", "please let me", "your preference",
    "ready to proceed", "want me to", "want to proceed",
]

if text:
    lines = text.split("\n")
    last_line = next((l.strip() for l in reversed(lines) if l.strip()), text)
    last_lower = last_line.lower()
    needs_input = last_line.endswith("?") or any(p in last_lower for p in question_phrases)
    status = "💬" if needs_input else "✅"
    if needs_input:
        summary = last_line  # Full question, no truncation
    else:
        summary = re.split(r'(?<=[.!?])\s|\n', text)[0].strip()
else:
    status = "✅"
    summary = "Task complete"

slack_text = f"{session_emoji} *{project_dir}:* {status} — {summary}"

payload = json.dumps({"channel": slack_user_id, "text": slack_text}).encode()
req = urllib.request.Request(
    "https://slack.com/api/chat.postMessage",
    data=payload,
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
