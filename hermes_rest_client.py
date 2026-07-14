import urllib.request
import urllib.error
import json
import argparse
import sys

def send_request(url, payload, api_key=None):
    headers = {
        "Content-Type": "application/json"
    }
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
        headers["X-API-Key"] = api_key

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            res_data = response.read().decode("utf-8")
            return response.status, json.loads(res_data)
    except urllib.error.HTTPError as e:
        try:
            err_data = e.read().decode("utf-8")
            return e.code, json.loads(err_data)
        except:
            return e.code, {"error": e.reason}
    except Exception as e:
        return 500, {"error": str(e)}

def main():
    parser = argparse.ArgumentParser(description="Hermes REST API Client")
    parser.add_argument("--host", required=True, help="Hermes API host (IP or domain)")
    parser.add_argument("--port", type=int, default=9877, help="Hermes API port (default: 9877)")
    parser.add_argument("--goal", required=True, help="Goal or query prompt to send to Hermes")
    parser.add_argument("--path", default="/", help="API path (default: /). Try /api/chat if / fails.")
    parser.add_argument("--api-key", help="API Authorization token / Key")

    args = parser.parse_args()

    # Normalize url
    base_url = f"http://{args.host}:{args.port}"
    target_url = f"{base_url}{args.path}"

    # Try both payload formats to ensure compatibility
    payload = {
        "goal": args.goal,
        "query": args.goal,
        "session_id": "antigravity-session",
        "user_id": "antigravity-user"
    }

    print(f"[*] Dispatching REST request to {target_url}...")
    status, response = send_request(target_url, payload, args.api_key)

    print(f"[*] Response Status: {status}")
    if status in (200, 201):
        print("\n[+] Response from Hermes:")
        if "response" in response:
            print(response["response"])
        elif "output" in response:
            print(response["output"])
        elif "result" in response:
            print(response["result"])
        else:
            print(json.dumps(response, indent=2, ensure_ascii=False))
    else:
        print(f"\n[!] Error from Hermes API: {json.dumps(response, indent=2)}")
        
        # Fallback helper
        if args.path == "/" and status in (404, 405, 500):
            print(f"\n[*] Trying fallback path '/api/chat'...")
            fallback_url = f"{base_url}/api/chat"
            status_fb, response_fb = send_request(fallback_url, payload, args.api_key)
            print(f"[*] Fallback Response Status: {status_fb}")
            if status_fb in (200, 201):
                print("\n[+] Response from Hermes (via /api/chat):")
                if "response" in response_fb:
                    print(response_fb["response"])
                else:
                    print(json.dumps(response_fb, indent=2, ensure_ascii=False))
            else:
                print(f"[!] Fallback failed: {json.dumps(response_fb, indent=2)}")

if __name__ == "__main__":
    main()
