import requests, json, os, sys, time
BASE = "http://127.0.0.1:8000"

def log(msg):
    print(f"[+] {msg}")

def get(url):
    r = requests.get(BASE + url)
    print(f"GET {url} -> {r.status_code}")
    try:
        print(r.json())
    except Exception:
        print(r.text)

def post(url, data, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.post(BASE + url, data=json.dumps(data), headers=headers)
    print(f"POST {url} -> {r.status_code}")
    try:
        print(r.json())
    except Exception:
        print(r.text)
    return r

# 1. health
get("/health")

# 2. register (ignore if already exists)
register_data = {"phone": "+923001234567", "name": "Test User", "role": "farmer"}
reg_res = post("/api/auth/register_local", register_data)

# 3. login
login_data = {"phone": "+923001234567"}
login_res = post("/api/auth/login_local", login_data)
if login_res.status_code == 200:
    token = login_res.json().get("token")
    # 4. antigravity process
    proc_data = {"raw_input": "I need a tractor urgently", "user_id": 1}
    post("/api/antigravity/process", proc_data, token=token)
else:
    print("Login failed, cannot test protected endpoint.")
