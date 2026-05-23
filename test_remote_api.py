import requests, json, uuid
BASE = 'https://ramsha00-kissanapp.hf.space'
phone = f'+92300{str(uuid.uuid4().int)[:7]}'
print(f'Testing against {BASE}')
print(f'Testing with phone: {phone}')

try:
    print('\n[+] GET /health')
    r = requests.get(BASE + '/health')
    print(r.status_code, r.text)

    print('\n[+] POST /api/auth/register_local')
    r = requests.post(BASE + '/api/auth/register_local', json={'phone': phone, 'name': 'Test User', 'role': 'farmer'})
    print(r.status_code, r.text)

    print('\n[+] POST /api/auth/login_local')
    r = requests.post(BASE + '/api/auth/login_local', json={'phone': phone})
    print(r.status_code, r.text)
    
    if r.status_code == 200:
        token = r.json().get('token')
        print('\n[+] GET /api/auth/me')
        headers = {'Authorization': f'Bearer {token}'}
        r = requests.get(BASE + '/api/auth/me', headers=headers)
        print(r.status_code, r.text)
        
        print('\n[+] POST /api/antigravity/process')
        r = requests.post(BASE + '/api/antigravity/process', json={'raw_input': 'I need a tractor urgently', 'user_id': r.json().get('user', {}).get('id', 1)}, headers=headers)
        print(r.status_code, r.text)
        
except Exception as e:
    print('Exception:', e)
