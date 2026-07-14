import os
import argparse
import sys
import io
import asyncio
from telethon import TelegramClient, events
from telethon.sessions import StringSession

# Force UTF-8 encoding for stdout and stderr to prevent UnicodeEncodeError on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')


async def main():
    parser = argparse.ArgumentParser(description="Hermes Telegram MTProto Client")
    parser.add_argument("--api-id", type=int, help="Telegram API ID")
    parser.add_argument("--api-hash", help="Telegram API Hash")
    parser.add_argument("--session", help="Telegram String Session")
    parser.add_argument("--test-dc", action="store_true", help="Connect to Telegram Test DC 2")
    parser.add_argument("--send-to", help="Receiver username or chat ID")
    parser.add_argument("--message", help="Message text to send")
    parser.add_argument("--listen", action="store_true", help="Listen to incoming messages")

    args = parser.parse_args()

    # Load .env file manually if it exists
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    os.environ[key.strip()] = val.strip()

    # Load from env if not provided
    api_id = args.api_id or int(os.environ.get("TELEGRAM_API_ID", 0) or 0)
    api_hash = args.api_hash or os.environ.get("TELEGRAM_API_HASH")
    session_str = args.session or os.environ.get("TELEGRAM_SESSION_STRING")

    if not api_id or not api_hash:
        print("[!] Error: TELEGRAM_API_ID and TELEGRAM_API_HASH are required.")
        sys.exit(1)

    # Initialize client
    session = StringSession(session_str) if session_str else StringSession()
    
    # Telethon client creation
    client = TelegramClient(session, api_id, api_hash)

    # Set custom DC if requested
    if args.test_dc:
        print("[*] Configuring connection to Test DC 2 (149.154.167.40:443)...")
        client.session.set_dc(2, "149.154.167.40", 443)
    
    print("[*] Starting Telegram client (will prompt for details if not authorized)...")
    await client.start()

    # Get and print session string if new
    new_session_str = client.session.save()
    if new_session_str != session_str:
        print("[+] Authorization successful! Here is your TELEGRAM_SESSION_STRING:")
        print("-" * 60)
        print(new_session_str)
        print("-" * 60)
        print("[*] Please save the above session string in your .env file as TELEGRAM_SESSION_STRING.")

    me = await client.get_me()
    print(f"[+] Connected as {me.first_name} (@{me.username or 'no_username'})")

    # Send message
    if args.send_to and args.message:
        target = args.send_to
        if target.isdigit() or (target.startswith("-") and target[1:].isdigit()):
            target = int(target)
        print(f"[*] Sending message to '{target}'...")
        try:
            await client.send_message(target, args.message)
            print("[+] Message sent successfully!")
        except Exception as e:
            print(f"[!] Failed to send message: {e}")

    # Listen mode
    if args.listen:
        print("[*] Listening for incoming messages (Press Ctrl+C to stop)...")
        @client.on(events.NewMessage)
        async def handler(event):
            sender = await event.get_sender()
            sender_name = getattr(sender, 'first_name', 'Unknown')
            sender_username = getattr(sender, 'username', 'no_username')
            print(f"[{event.date}] From {sender_name} (@{sender_username}): {event.text}")

        await client.run_until_disconnected()
    else:
        await client.disconnect()

if __name__ == "__main__":
    asyncio.run(main())
