#!/bin/bash
set -e

CONFIG="$HOME/.claude/slack-notify-config"

echo "Setting up slack-notify credentials..."
echo ""

# ── Prerequisites ──────────────────────────────────────────────────────────────

for cmd in op python3 curl claude; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

# ── 1Password sign-in ──────────────────────────────────────────────────────────

if ! op whoami &>/dev/null; then
  echo "Sign in to 1Password (required to fetch the Slack bot token):"
  op signin
  if ! op whoami &>/dev/null; then
    echo "Error: 1Password sign-in failed." >&2
    exit 1
  fi
fi

# ── Fetch Slack bot token ──────────────────────────────────────────────────────

echo "Fetching Slack bot token from 1Password..."
SLACK_TOKEN=$(op read "op://Engineering/SLACK_CLAUDE_NOTIFICATION_TOKEN/password")

if [ -z "$SLACK_TOKEN" ]; then
  echo "Error: Could not read Slack token from 1Password." >&2
  exit 1
fi

# ── Look up Slack user ID ──────────────────────────────────────────────────────

echo "Looking up your Slack user ID..."
EMAIL=$(CLAUDECODE="" claude auth status 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('email',''))" 2>/dev/null)

if [ -z "$EMAIL" ]; then
  echo "Error: Could not determine your email from Claude account." >&2
  exit 1
fi

SLACK_USER_ID=$(curl -s "https://slack.com/api/users.lookupByEmail?email=$EMAIL" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('user',{}).get('id',''))" 2>/dev/null)

if [ -z "$SLACK_USER_ID" ]; then
  echo "Error: Could not find Slack user for $EMAIL. Make sure the bot has the users:read.email scope." >&2
  exit 1
fi

# ── Write config ───────────────────────────────────────────────────────────────

cat > "$CONFIG" << CONF
SLACK_TOKEN=${SLACK_TOKEN}
SLACK_USER_ID=${SLACK_USER_ID}
CONF
chmod 600 "$CONFIG"

# ── Send test DM ───────────────────────────────────────────────────────────────

echo "Sending test DM to confirm everything works..."
RESPONSE=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{\"channel\":\"$SLACK_USER_ID\",\"text\":\"✅ slack-notify is set up! You will receive a DM here whenever Claude finishes a task.\"}")

if echo "$RESPONSE" | python3 -c "import json,sys; assert json.load(sys.stdin).get('ok')" 2>/dev/null; then
  echo ""
  echo "✅ All done! Check Slack for your test DM."
else
  ERROR=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','unknown'))" 2>/dev/null)
  echo "Warning: Test DM failed ($ERROR). Config was saved — check your Slack app permissions." >&2
fi
