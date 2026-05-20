import urllib.request
import urllib.error
import json
import uuid

phone = f"+92300{str(uuid.uuid4().int)[:7]}"
print(f"Testing with phone: {phone}")

# 1. Register
print("\n--- 1. Testing Registration ---")
req_reg = urllib.request.Request(
    'http://localhost:8000/api/auth/register_local',
    data=json.dumps({"phone": phone, "name": "Test Farmer", "role": "farmer"}).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
try:
    resp_reg = urllib.request.urlopen(req_reg)
    data_reg = json.loads(resp_reg.read().decode())
    print("SUCCESS:", data_reg['status'])
    token = data_reg['token']
except urllib.error.HTTPError as e:
    print("FAILED:", e.code, e.read().decode())
    exit(1)

# 2. Login
print("\n--- 2. Testing Login ---")
req_log = urllib.request.Request(
    'http://localhost:8000/api/auth/login_local',
    data=json.dumps({"phone": phone}).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
try:
    resp_log = urllib.request.urlopen(req_log)
    data_log = json.loads(resp_log.read().decode())
    print("SUCCESS:", data_log['status'])
except urllib.error.HTTPError as e:
    print("FAILED:", e.code, e.read().decode())
    exit(1)

# 3. Get /me
print("\n--- 3. Testing Secure /me Endpoint ---")
req_me = urllib.request.Request(
    'http://localhost:8000/api/auth/me',
    headers={'Authorization': f'Bearer {token}'},
    method='GET'
)
try:
    resp_me = urllib.request.urlopen(req_me)
    data_me = json.loads(resp_me.read().decode())
    print("SUCCESS: Retrieved User Profile -> Name:", data_me['name'], "| Phone:", data_me['phone'])
except urllib.error.HTTPError as e:
    print("FAILED:", e.code, e.read().decode())
    exit(1)
