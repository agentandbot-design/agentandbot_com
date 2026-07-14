import socket
import json
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Hermes ACP (Agent Communication Protocol) TCP Client")
    parser.add_argument("--host", default="localhost", help="Hermes ACP host (default: localhost)")
    parser.add_argument("--port", type=int, default=9876, help="Hermes ACP port (default: 9876)")
    parser.add_argument("--prompt", required=True, help="Task prompt to send to Hermes")
    parser.add_argument("--task-id", default="antigravity-task-1", help="Custom task identifier")
    parser.add_argument("--toolsets", nargs="+", default=["terminal", "file"], help="Tools Hermes can use (default: terminal file)")

    args = parser.parse_args()

    # TCP Socket Connection
    print(f"[*] Connecting to Hermes ACP at {args.host}:{args.port}...")
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((args.host, args.port))
    except Exception as e:
        print(f"[!] Connection failed: {e}")
        sys.exit(1)

    print("[*] Connection established. Performing handshake...")
    
    # 1. Send Handshake
    handshake = {
        "type": "handshake",
        "version": "1.0",
        "client": "antigravity-agent"
    }
    
    try:
        s.sendall((json.dumps(handshake) + "\n").encode("utf-8"))
        
        # Read Handshake Response (expecting single line JSON)
        buffer = ""
        while "\n" not in buffer:
            data = s.recv(1024).decode("utf-8")
            if not data:
                break
            buffer += data
            
        line, remainder = buffer.split("\n", 1)
        response = json.loads(line)
        
        if response.get("status") != "ok":
            print(f"[!] Handshake rejected: {response}")
            s.close()
            sys.exit(1)
            
        print("[+] Handshake successful! Sending task...")
        
        # 2. Send Task
        task = {
            "type": "task",
            "task_id": args.task_id,
            "prompt": args.prompt,
            "toolsets": args.toolsets
        }
        s.sendall((json.dumps(task) + "\n").encode("utf-8"))
        
        # 3. Read Task Outputs (Streaming Progress & Result/Error)
        buffer = remainder
        while True:
            # Check if we have complete lines in buffer
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                if not line.strip():
                    continue
                
                frame = json.loads(line)
                frame_type = frame.get("type")
                
                if frame_type == "progress":
                    print(f"[*] Progress: {frame.get('message')}")
                elif frame_type == "result":
                    print(f"\n[+] Task Completed Successfully!")
                    print(f"Output:\n{frame.get('output')}")
                    s.close()
                    return
                elif frame_type == "error":
                    print(f"\n[!] Task Failed!")
                    print(f"Error Message: {frame.get('message')}")
                    s.close()
                    sys.exit(1)
                else:
                    print(f"[?] Unknown frame type: {frame}")
            
            # Read more data from socket
            data = s.recv(4096).decode("utf-8")
            if not data:
                print("[!] Connection closed unexpectedly by Hermes.")
                break
            buffer += data

    except Exception as e:
        print(f"[!] Error during communication: {e}")
    finally:
        s.close()

if __name__ == "__main__":
    main()
