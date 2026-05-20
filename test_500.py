import urllib.request, json
req = urllib.request.Request('http://localhost:8000/api/auth/register_local', data=json.dumps({'phone': '+92300000000', 'name': 'T', 'role': 'farmer'}).encode('utf-8'), headers={'Content-Type': 'application/json'}, method='POST')
try:
    print(urllib.request.urlopen(req).read().decode())
except Exception as e:
    print(e.read().decode())
