#!/bin/bash
set -e

CREATED_TAGS=($1)
AFFECTED_BRANCHES=($2)

# Check if we have any tags to process
if [[ ${#CREATED_TAGS[@]} -eq 0 ]]; then
    echo "No tags created, skipping notification."
    exit 0
fi

python3 <<'EOF'
import os
import sys
import re
import requests

def send_telegram_notification(chat_id, message, bot_key): 
    url = f"https://api.telegram.org/bot{bot_key}/sendMessage"
    payload = { 
        "chat_id": chat_id, 
        "text": message, 
        "parse_mode": "MarkdownV2",
    }

    try: 
        response = requests.post(url, json=payload)
        response.raise_for_status()
        print(f"✅ Message sent successfully to chat {chat_id}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to send message to chat {chat_id}: {e}")
        return False

def main(): 
    bot_key = os.getenv("TELEGRAM_RELEASE_BOT_KEY")
    dev_chat_id = os.getenv("TELEGRAM_DEV_RELEASE_CHAT_ID")
    rc_chat_id = os.getenv("TELEGRAM_RC_RELEASE_CHAT_ID")

    created_tags = os.getenv("CREATED_TAGS", "").split()
    affected_branches = os.getenv("AFFECTED_BRANCHES", "").split()

    if not bot_key: 
        print("❌ TELEGRAM_RELEASE_BOT_KEY not found.")
        sys.exit(1)

    # Separate develop and RC tags
    develop_tags = []
    rc_tags = []
    
    for tag, branch in zip(created_tags, created_branches):
        if branch == 'develop':
            develop_tags.append(tag)
        else:
            rc_tags.append(tag)

    # Send notification for develop branch
    if develop_tags and dev_chat_id: 
        message = "🚀 *Development Build Started (TEST ONLY)*\n\n"
        message += "New Tags created for develop branch:\n"
        for tag in develop_tags: 
            message += f"• `{tag}`\n"

        if send_telegram_notification(dev_chat_id, message, bot_key):
            print(f"✅ Notification sent to development chat {dev_chat_id}")
    
    # Send notification for RC branches
    if rc_tags and rc_chat_id: 
        message = "🏗️ *RC Build Started (TEST ONLY)*\n\n"
        message += "New tags created for RC branches:\n"
        for tag in rc_tags: 
            message += f"• `{tag}`\n"

        if send_telegram_notification(rc_chat_id, message, bot_key):
            print(f"✅ Notification sent to RC chat {rc_chat_id}")
    
if __name__ == "__main__":
    main()
EOF